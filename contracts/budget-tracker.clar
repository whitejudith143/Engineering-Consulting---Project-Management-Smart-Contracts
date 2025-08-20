;; Budget Tracker Contract
;; Financial tracking and payment processing for engineering projects

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-BUDGET-NOT-FOUND (err u501))
(define-constant ERR-EXPENSE-NOT-FOUND (err u502))
(define-constant ERR-INSUFFICIENT-FUNDS (err u503))
(define-constant ERR-INVALID-INPUT (err u504))
(define-constant ERR-PAYMENT-FAILED (err u505))
(define-constant ERR-ALREADY-APPROVED (err u506))

;; Constants
(define-constant EXPENSE-STATUS-PENDING u1)
(define-constant EXPENSE-STATUS-APPROVED u2)
(define-constant EXPENSE-STATUS-PAID u3)
(define-constant EXPENSE-STATUS-REJECTED u4)

(define-constant EXPENSE-CATEGORY-LABOR u1)
(define-constant EXPENSE-CATEGORY-MATERIALS u2)
(define-constant EXPENSE-CATEGORY-EQUIPMENT u3)
(define-constant EXPENSE-CATEGORY-TRAVEL u4)
(define-constant EXPENSE-CATEGORY-OTHER u5)

;; Data variables
(define-data-var next-expense-id uint u1)

;; Data maps
(define-map project-budgets
  { project-id: uint }
  {
    total-budget: uint,
    allocated-budget: uint,
    spent-budget: uint,
    remaining-budget: uint,
    budget-manager: principal,
    created-date: uint
  }
)

(define-map expenses
  { expense-id: uint }
  {
    project-id: uint,
    category: uint,
    amount: uint,
    description: (string-ascii 500),
    submitter: principal,
    approver: (optional principal),
    status: uint,
    submission-date: uint,
    approval-date: (optional uint),
    payment-date: (optional uint),
    receipt-hash: (optional (buff 32))
  }
)

(define-map budget-allocations
  { project-id: uint, category: uint }
  {
    allocated-amount: uint,
    spent-amount: uint,
    remaining-amount: uint
  }
)

(define-map payment-records
  { expense-id: uint }
  {
    payment-amount: uint,
    payment-method: (string-ascii 50),
    transaction-hash: (buff 32),
    payment-date: uint,
    paid-by: principal
  }
)

;; Read-only functions
(define-read-only (get-project-budget (project-id uint))
  (map-get? project-budgets { project-id: project-id })
)

(define-read-only (get-expense (expense-id uint))
  (map-get? expenses { expense-id: expense-id })
)

(define-read-only (get-budget-allocation (project-id uint) (category uint))
  (map-get? budget-allocations { project-id: project-id, category: category })
)

(define-read-only (get-payment-record (expense-id uint))
  (map-get? payment-records { expense-id: expense-id })
)

(define-read-only (calculate-remaining-budget (project-id uint))
  (match (get-project-budget project-id)
    budget-data (- (get total-budget budget-data) (get spent-budget budget-data))
    u0
  )
)

;; Public functions
(define-public (create-project-budget
  (project-id uint)
  (total-budget uint)
  (budget-manager principal)
)
  (let ((caller tx-sender))
    ;; Validate inputs
    (asserts! (> total-budget u0) ERR-INVALID-INPUT)

    ;; Create budget
    (map-set project-budgets
      { project-id: project-id }
      {
        total-budget: total-budget,
        allocated-budget: u0,
        spent-budget: u0,
        remaining-budget: total-budget,
        budget-manager: budget-manager,
        created-date: block-height
      }
    )

    (ok true)
  )
)

(define-public (allocate-budget
  (project-id uint)
  (category uint)
  (amount uint)
)
  (let
    (
      (caller tx-sender)
      (budget-data (unwrap! (get-project-budget project-id) ERR-BUDGET-NOT-FOUND))
      (current-allocation (default-to
        { allocated-amount: u0, spent-amount: u0, remaining-amount: u0 }
        (get-budget-allocation project-id category)
      ))
    )
    ;; Only budget manager can allocate
    (asserts! (is-eq caller (get budget-manager budget-data)) ERR-NOT-AUTHORIZED)

    ;; Validate category and amount
    (asserts! (and (>= category u1) (<= category u5)) ERR-INVALID-INPUT)
    (asserts! (> amount u0) ERR-INVALID-INPUT)

    ;; Check if enough budget available
    (let
      (
        (new-allocated (+ (get allocated-budget budget-data) amount))
        (available-budget (- (get total-budget budget-data) (get allocated-budget budget-data)))
      )
      (asserts! (<= amount available-budget) ERR-INSUFFICIENT-FUNDS)

      ;; Update budget allocation
      (map-set budget-allocations
        { project-id: project-id, category: category }
        {
          allocated-amount: (+ (get allocated-amount current-allocation) amount),
          spent-amount: (get spent-amount current-allocation),
          remaining-amount: (+ (get remaining-amount current-allocation) amount)
        }
      )

      ;; Update project budget
      (map-set project-budgets
        { project-id: project-id }
        (merge budget-data { allocated-budget: new-allocated })
      )

      (ok true)
    )
  )
)

(define-public (submit-expense
  (project-id uint)
  (category uint)
  (amount uint)
  (description (string-ascii 500))
  (receipt-hash (optional (buff 32)))
)
  (let
    (
      (expense-id (var-get next-expense-id))
      (caller tx-sender)
      (budget-data (unwrap! (get-project-budget project-id) ERR-BUDGET-NOT-FOUND))
    )
    ;; Validate inputs
    (asserts! (and (>= category u1) (<= category u5)) ERR-INVALID-INPUT)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    ;; Create expense
    (map-set expenses
      { expense-id: expense-id }
      {
        project-id: project-id,
        category: category,
        amount: amount,
        description: description,
        submitter: caller,
        approver: none,
        status: EXPENSE-STATUS-PENDING,
        submission-date: block-height,
        approval-date: none,
        payment-date: none,
        receipt-hash: receipt-hash
      }
    )

    ;; Increment next ID
    (var-set next-expense-id (+ expense-id u1))

    (ok expense-id)
  )
)

(define-public (approve-expense (expense-id uint))
  (let
    (
      (caller tx-sender)
      (expense-data (unwrap! (get-expense expense-id) ERR-EXPENSE-NOT-FOUND))
      (project-id (get project-id expense-data))
      (budget-data (unwrap! (get-project-budget project-id) ERR-BUDGET-NOT-FOUND))
      (category (get category expense-data))
      (amount (get amount expense-data))
    )
    ;; Only budget manager can approve
    (asserts! (is-eq caller (get budget-manager budget-data)) ERR-NOT-AUTHORIZED)

    ;; Expense must be pending
    (asserts! (is-eq (get status expense-data) EXPENSE-STATUS-PENDING) ERR-INVALID-INPUT)

    ;; Check if enough budget in category
    (let
      (
        (allocation (unwrap! (get-budget-allocation project-id category) ERR-BUDGET-NOT-FOUND))
        (remaining-in-category (get remaining-amount allocation))
      )
      (asserts! (>= remaining-in-category amount) ERR-INSUFFICIENT-FUNDS)

      ;; Approve expense
      (map-set expenses
        { expense-id: expense-id }
        (merge expense-data
          {
            status: EXPENSE-STATUS-APPROVED,
            approver: (some caller),
            approval-date: (some block-height)
          }
        )
      )

      (ok true)
    )
  )
)

(define-public (process-payment (expense-id uint) (transaction-hash (buff 32)))
  (let
    (
      (caller tx-sender)
      (expense-data (unwrap! (get-expense expense-id) ERR-EXPENSE-NOT-FOUND))
      (project-id (get project-id expense-data))
      (budget-data (unwrap! (get-project-budget project-id) ERR-BUDGET-NOT-FOUND))
      (category (get category expense-data))
      (amount (get amount expense-data))
    )
    ;; Only budget manager can process payment
    (asserts! (is-eq caller (get budget-manager budget-data)) ERR-NOT-AUTHORIZED)

    ;; Expense must be approved
    (asserts! (is-eq (get status expense-data) EXPENSE-STATUS-APPROVED) ERR-INVALID-INPUT)

    ;; Update expense status
    (map-set expenses
      { expense-id: expense-id }
      (merge expense-data
        {
          status: EXPENSE-STATUS-PAID,
          payment-date: (some block-height)
        }
      )
    )

    ;; Record payment
    (map-set payment-records
      { expense-id: expense-id }
      {
        payment-amount: amount,
        payment-method: "STX Transfer",
        transaction-hash: transaction-hash,
        payment-date: block-height,
        paid-by: caller
      }
    )

    ;; Update budget tracking
    (let
      (
        (allocation (unwrap! (get-budget-allocation project-id category) ERR-BUDGET-NOT-FOUND))
        (new-spent-budget (+ (get spent-budget budget-data) amount))
        (new-remaining-budget (- (get remaining-budget budget-data) amount))
      )
      ;; Update category allocation
      (map-set budget-allocations
        { project-id: project-id, category: category }
        (merge allocation
          {
            spent-amount: (+ (get spent-amount allocation) amount),
            remaining-amount: (- (get remaining-amount allocation) amount)
          }
        )
      )

      ;; Update project budget
      (map-set project-budgets
        { project-id: project-id }
        (merge budget-data
          {
            spent-budget: new-spent-budget,
            remaining-budget: new-remaining-budget
          }
        )
      )

      (ok true)
    )
  )
)

(define-public (reject-expense (expense-id uint))
  (let
    (
      (caller tx-sender)
      (expense-data (unwrap! (get-expense expense-id) ERR-EXPENSE-NOT-FOUND))
      (project-id (get project-id expense-data))
      (budget-data (unwrap! (get-project-budget project-id) ERR-BUDGET-NOT-FOUND))
    )
    ;; Only budget manager can reject
    (asserts! (is-eq caller (get budget-manager budget-data)) ERR-NOT-AUTHORIZED)

    ;; Expense must be pending
    (asserts! (is-eq (get status expense-data) EXPENSE-STATUS-PENDING) ERR-INVALID-INPUT)

    ;; Reject expense
    (map-set expenses
      { expense-id: expense-id }
      (merge expense-data
        {
          status: EXPENSE-STATUS-REJECTED,
          approver: (some caller),
          approval-date: (some block-height)
        }
      )
    )

    (ok true)
  )
)
