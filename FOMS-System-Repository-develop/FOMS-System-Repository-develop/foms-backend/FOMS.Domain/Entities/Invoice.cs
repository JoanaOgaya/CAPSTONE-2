using System;

namespace FOMS.Domain.Entities;

public class Invoice
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string InvoiceNo { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public Client? Client { get; set; }
    public string? ClientName { get; set; }
    public string? BillingDate { get; set; }
    public string? DueDate { get; set; }
    public decimal FreightCharges { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal Subtotal { get; set; }
    public decimal VatRate { get; set; } = 0.12m;
    public decimal VatAmount { get; set; }
    public decimal Surcharge { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal AmountPaid { get; set; }
    public decimal Balance { get; set; }
    public string PaymentStatus { get; set; } = "Unpaid"; // "Paid" | "Unpaid" (derived from payments and balance; never store "Overdue")
    public string? DocumentStatus { get; set; } = "Draft"; // "Draft" | "ForReview" | "Approved" | "Sent" | "Received" | "Disputed" | "Void"
    public string? PaymentValidationStatus { get; set; } // Legacy field kept for backward compatibility
    public bool CreatedBeforeBillingRun { get; set; } = false;
    public string? AgingBucket { get; set; } = "Current"; // Derived dynamically; never store as static authority
    public int DaysOverdue { get; set; } // Derived dynamically
    public string? Description { get; set; }
    public string? EncodedBy { get; set; }
    public string? DateEncoded { get; set; }
    public string? LastUpdated { get; set; }
    public string? UpdatedBy { get; set; }
    public bool Archived { get; set; } = false;
    public string? WaybillIds { get; set; }
}
