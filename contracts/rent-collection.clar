;; Rent Collection Contract
;; Automates rent payments, late fees, and payment tracking

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-PAYMENT-NOT-FOUND (err u301))
(define-constant ERR-LEASE-NOT-FOUND (err u302))
(define-constant ERR-INVALID-INPUT (err u303))
(define-constant ERR-PAYMENT-ALREADY-MADE (err u304))
(define-constant ERR-INSUFFICIENT-FUNDS (err u305))
(define-constant ERR-PAYMENT-NOT-DUE (err u306))

;; Payment Status Constants
(define-constant PAYMENT-STATUS-PENDING u0)
(define-constant PAYMENT-STATUS-PAID u1)
(define-constant PAYMENT-STATUS-LATE u2)
(define-constant PAYMENT-STATUS-OVERDUE u3)

;; Late Fee Configuration
(define-constant LATE-FEE-GRACE-PERIOD u7) ;; 7 days grace period
(define-constant LATE-FEE-PERCENTAGE u5) ;; 5% late fee
(define-constant OVERDUE-THRESHOLD u30) ;; 30 days overdue threshold

;; Data Variables
(define-data-var next-payment-id uint u1)

;; Data Maps
(define-map rent-payments
  { payment-id: uint }
  {
    lease-id: uint,
    tenant: principal,
    landlord: principal,
    amount-due: uint,
    amount-paid: uint,
    late-fee: uint,
    due-date: uint,
    paid-date: (optional uint),
    status: uint,
    created-at: uint
  }
)

(define-map lease-payment-schedule
  { lease-id: uint }
  {
    next-due-date: uint,
    monthly-amount: uint,
    payment-ids: (list 120 uint) ;; Up to 10 years of monthly payments
  }
)

(define-map tenant-payment-history
  { tenant: principal }
  {
    total-payments: uint,
    on-time-payments: uint,
    late-payments: uint,
    total-late-fees: uint
  }
)

;; Read-only functions
(define-read-only (get-payment (payment-id uint))
  (map-get? rent-payments { payment-id: payment-id })
)

(define-read-only (get-lease-payment-schedule (lease-id uint))
  (map-get? lease-payment-schedule { lease-id: lease-id })
)

(define-read-only (get-tenant-payment-history (tenant principal))
  (map-get? tenant-payment-history { tenant: tenant })
)

(define-read-only (calculate-late-fee (amount uint))
  (/ (* amount LATE-FEE-PERCENTAGE) u100)
)

(define-read-only (is-payment-overdue (payment-id uint))
  (match (map-get? rent-payments { payment-id: payment-id })
    payment (and
      (not (is-eq (get status payment) PAYMENT-STATUS-PAID))
      (>= block-height (+ (get due-date payment) OVERDUE-THRESHOLD))
    )
    false
  )
)

(define-read-only (is-payment-late (payment-id uint))
  (match (map-get? rent-payments { payment-id: payment-id })
    payment (and
      (not (is-eq (get status payment) PAYMENT-STATUS-PAID))
      (>= block-height (+ (get due-date payment) LATE-FEE-GRACE-PERIOD))
    )
    false
  )
)

(define-read-only (get-next-payment-id)
  (var-get next-payment-id)
)

;; Private functions
(define-private (update-tenant-payment-history (tenant principal) (on-time bool) (late-fee uint))
  (let
    (
      (current-history (default-to
        { total-payments: u0, on-time-payments: u0, late-payments: u0, total-late-fees: u0 }
        (map-get? tenant-payment-history { tenant: tenant })
      ))
    )
    (map-set tenant-payment-history
      { tenant: tenant }
      {
        total-payments: (+ (get total-payments current-history) u1),
        on-time-payments: (if on-time (+ (get on-time-payments current-history) u1) (get on-time-payments current-history)),
        late-payments: (if on-time (get late-payments current-history) (+ (get late-payments current-history) u1)),
        total-late-fees: (+ (get total-late-fees current-history) late-fee)
      }
    )
  )
)

;; Public functions
(define-public (initialize-payment-schedule (lease-id uint) (monthly-rent uint) (start-date uint))
  (let
    (
      (first-due-date (+ start-date u4320)) ;; Approximately 30 days in blocks
    )
    (asserts! (> monthly-rent u0) ERR-INVALID-INPUT)
    (asserts! (> start-date u0) ERR-INVALID-INPUT)

    (map-set lease-payment-schedule
      { lease-id: lease-id }
      {
        next-due-date: first-due-date,
        monthly-amount: monthly-rent,
        payment-ids: (list)
      }
    )
    (ok true)
  )
)

(define-public (generate-monthly-payment (lease-id uint) (tenant principal) (landlord principal))
  (let
    (
      (payment-id (var-get next-payment-id))
      (schedule (unwrap! (map-get? lease-payment-schedule { lease-id: lease-id }) ERR-LEASE-NOT-FOUND))
      (due-date (get next-due-date schedule))
      (amount (get monthly-amount schedule))
      (current-payment-ids (get payment-ids schedule))
    )
    (asserts! (<= block-height due-date) ERR-PAYMENT-NOT-DUE)

    (map-set rent-payments
      { payment-id: payment-id }
      {
        lease-id: lease-id,
        tenant: tenant,
        landlord: landlord,
        amount-due: amount,
        amount-paid: u0,
        late-fee: u0,
        due-date: due-date,
        paid-date: none,
        status: PAYMENT-STATUS-PENDING,
        created-at: block-height
      }
    )

    (map-set lease-payment-schedule
      { lease-id: lease-id }
      (merge schedule {
        next-due-date: (+ due-date u4320), ;; Next month
        payment-ids: (unwrap! (as-max-len? (append current-payment-ids payment-id) u120) ERR-INVALID-INPUT)
      })
    )

    (var-set next-payment-id (+ payment-id u1))
    (ok payment-id)
  )
)

(define-public (make-rent-payment (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? rent-payments { payment-id: payment-id }) ERR-PAYMENT-NOT-FOUND))
      (is-late (is-payment-late payment-id))
      (late-fee (if is-late (calculate-late-fee (get amount-due payment)) u0))
      (total-amount (+ (get amount-due payment) late-fee))
    )
    (asserts! (is-eq tx-sender (get tenant payment)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status payment) PAYMENT-STATUS-PAID)) ERR-PAYMENT-ALREADY-MADE)

    ;; In a real implementation, this would transfer STX from tenant to landlord
    ;; For now, we'll just update the payment record

    (map-set rent-payments
      { payment-id: payment-id }
      (merge payment {
        amount-paid: total-amount,
        late-fee: late-fee,
        paid-date: (some block-height),
        status: PAYMENT-STATUS-PAID
      })
    )

    (update-tenant-payment-history (get tenant payment) (not is-late) late-fee)
    (ok total-amount)
  )
)

(define-public (update-payment-status (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? rent-payments { payment-id: payment-id }) ERR-PAYMENT-NOT-FOUND))
    )
    (if (not (is-eq (get status payment) PAYMENT-STATUS-PAID))
      (let
        (
          (new-status (if (is-payment-overdue payment-id)
            PAYMENT-STATUS-OVERDUE
            (if (is-payment-late payment-id)
              PAYMENT-STATUS-LATE
              PAYMENT-STATUS-PENDING
            )
          ))
        )
        (map-set rent-payments
          { payment-id: payment-id }
          (merge payment { status: new-status })
        )
        (ok new-status)
      )
      (ok (get status payment))
    )
  )
)

(define-public (process-late-fee (payment-id uint))
  (let
    (
      (payment (unwrap! (map-get? rent-payments { payment-id: payment-id }) ERR-PAYMENT-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender (get landlord payment)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (is-payment-late payment-id) ERR-PAYMENT-NOT-DUE)
    (asserts! (not (is-eq (get status payment) PAYMENT-STATUS-PAID)) ERR-PAYMENT-ALREADY-MADE)

    (let
      (
        (late-fee (calculate-late-fee (get amount-due payment)))
      )
      (map-set rent-payments
        { payment-id: payment-id }
        (merge payment {
          late-fee: late-fee,
          status: PAYMENT-STATUS-LATE
        })
      )
      (ok late-fee)
    )
  )
)
