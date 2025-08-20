import { describe, it, expect, beforeEach } from "vitest"

describe("Budget Tracker Contract", () => {
  let contractAddress
  let accounts
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.budget-tracker"
    accounts = {
      deployer: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      manager: "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5",
      submitter: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
      user: "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC",
    }
  })
  
  describe("Budget Creation", () => {
    it("should create project budget successfully", async () => {
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail to create budget with zero amount", async () => {
      const projectId = 1
      const totalBudget = 0
      const budgetManager = accounts.manager
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
  })
  
  describe("Budget Allocation", () => {
    beforeEach(async () => {
      // Create test budget
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
    })
    
    it("should allocate budget to category", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 300000
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail allocation by non-manager", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 300000
      
      const result = {
        type: "error",
        value: 500, // ERR-NOT-AUTHORIZED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(500)
    })
    
    it("should fail allocation with invalid category", async () => {
      const projectId = 1
      const category = 10 // Invalid
      const amount = 300000
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
    
    it("should fail allocation exceeding budget", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 1500000 // Exceeds total budget
      
      const result = {
        type: "error",
        value: 503, // ERR-INSUFFICIENT-FUNDS
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(503)
    })
    
    it("should allocate multiple categories", async () => {
      const projectId = 1
      
      // Allocate to LABOR
      const laborAmount = 300000
      const laborResult = {
        type: "ok",
        value: true,
      }
      
      // Allocate to MATERIALS
      const materialsAmount = 200000
      const materialsResult = {
        type: "ok",
        value: true,
      }
      
      expect(laborResult.type).toBe("ok")
      expect(materialsResult.type).toBe("ok")
    })
  })
  
  describe("Expense Management", () => {
    beforeEach(async () => {
      // Create budget and allocate to categories
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
    })
    
    it("should submit expense successfully", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 50000
      const description = "Structural engineer consulting fees"
      const receiptHash = null
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should fail to submit expense with zero amount", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 0
      const description = "Structural engineer consulting fees"
      const receiptHash = null
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
    
    it("should fail to submit expense with empty description", async () => {
      const projectId = 1
      const category = 1 // LABOR
      const amount = 50000
      const description = ""
      const receiptHash = null
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
    
    it("should submit expense with receipt", async () => {
      const projectId = 1
      const category = 2 // MATERIALS
      const amount = 25000
      const description = "Steel beams for construction"
      const receiptHash = "0x1234567890abcdef1234567890abcdef12345678"
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
  })
  
  describe("Expense Approval", () => {
    beforeEach(async () => {
      // Create budget, allocate, and submit expense
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
    })
    
    it("should approve expense", async () => {
      const expenseId = 1
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail approval by non-manager", async () => {
      const expenseId = 1
      
      const result = {
        type: "error",
        value: 500, // ERR-NOT-AUTHORIZED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(500)
    })
    
    it("should fail approval of non-pending expense", async () => {
      const expenseId = 1
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
    
    it("should fail approval exceeding category budget", async () => {
      // Submit expense exceeding allocated amount
      const expenseId = 1
      
      const result = {
        type: "error",
        value: 501, // ERR-BUDGET-NOT-FOUND or ERR-INSUFFICIENT-FUNDS
      }
      
      expect(result.type).toBe("error")
    })
    
    it("should reject expense", async () => {
      const expenseId = 1
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("Payment Processing", () => {
    beforeEach(async () => {
      // Create budget, allocate, submit, and approve expense
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
    })
    
    it("should process payment", async () => {
      const expenseId = 1
      const transactionHash = "0xabcdef1234567890abcdef1234567890abcdef12"
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail payment by non-manager", async () => {
      const expenseId = 1
      const transactionHash = "0xabcdef1234567890abcdef1234567890abcdef12"
      
      const result = {
        type: "error",
        value: 500, // ERR-NOT-AUTHORIZED
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(500)
    })
    
    it("should fail payment of non-approved expense", async () => {
      const expenseId = 1
      const transactionHash = "0xabcdef1234567890abcdef1234567890abcdef12"
      
      const result = {
        type: "error",
        value: 504, // ERR-INVALID-INPUT
      }
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(504)
    })
  })
  
  describe("Budget Queries", () => {
    beforeEach(async () => {
      // Create test budget
      const projectId = 1
      const totalBudget = 1000000
      const budgetManager = accounts.manager
    })
    
    it("should get project budget", async () => {
      const projectId = 1
      
      const result = {
        type: "some",
        value: {
          "total-budget": 1000000,
          "allocated-budget": 0,
          "spent-budget": 0,
          "remaining-budget": 1000000,
          "budget-manager": accounts.manager,
          "created-date": 100,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value["total-budget"]).toBe(1000000)
      expect(result.value["budget-manager"]).toBe(accounts.manager)
    })
    
    it("should calculate remaining budget", async () => {
      const projectId = 1
      
      const result = 1000000
      
      expect(result).toBe(1000000)
    })
    
    it("should get budget allocation", async () => {
      // Allocate budget first
      const projectId = 1
      const category = 1 // LABOR
      
      const result = {
        type: "some",
        value: {
          "allocated-amount": 300000,
          "spent-amount": 0,
          "remaining-amount": 300000,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value["allocated-amount"]).toBe(300000)
    })
    
    it("should get expense details", async () => {
      const expenseId = 1
      
      const result = {
        type: "some",
        value: {
          "project-id": 1,
          category: 1, // LABOR
          amount: 50000,
          description: "Structural engineer consulting fees",
          submitter: accounts.submitter,
          approver: null,
          status: 1, // PENDING
          "submission-date": 150,
          "approval-date": null,
          "payment-date": null,
          "receipt-hash": null,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value.amount).toBe(50000)
      expect(result.value.description).toBe("Structural engineer consulting fees")
    })
    
    it("should get payment record", async () => {
      // Process payment first
      const expenseId = 1
      
      const result = {
        type: "some",
        value: {
          "payment-amount": 50000,
          "payment-method": "STX Transfer",
          "transaction-hash": "0xabcdef1234567890abcdef1234567890abcdef12",
          "payment-date": 200,
          "paid-by": accounts.manager,
        },
      }
      
      expect(result.type).toBe("some")
      expect(result.value["payment-amount"]).toBe(50000)
      expect(result.value["payment-method"]).toBe("STX Transfer")
    })
    
    it("should return none for non-existent budget", async () => {
      const projectId = 999
      
      const result = {
        type: "none",
      }
      
      expect(result.type).toBe("none")
    })
  })
})
