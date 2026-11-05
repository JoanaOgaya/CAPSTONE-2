using System;

namespace FOMS.Domain.Entities;

public class Payment
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string OrNumber { get; set; } = string.Empty;
    public string InvoiceId { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public string ClientName { get; set; } = string.Empty;
    public string PaymentDate { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Flow { get; set; } = "inflow"; // "inflow" or "outflow"
    public string PaymentMethod { get; set; } = "Bank Transfer"; // "Check" | "Bank Transfer" | "GCash" | "Maya"
    public string ReferenceNumber { get; set; } = string.Empty;
    public string? ProofImageUrl { get; set; }
    public string? Remarks { get; set; }
    public string RecordedBy { get; set; } = string.Empty;
    public string DateRecorded { get; set; } = string.Empty;

    // Validation & Migration Flags
    public string? SpeedPayReference { get; set; } // Historical read-only reference
    public string? PayMongoReference { get; set; } // Historical read-only reference
    public string PaymentStatus { get; set; } = "Pending Finance Validation";
    public bool RequiresRevalidation { get; set; } = false;
    public bool FlaggedForFinanceManager { get; set; } = false;
    public string? OrReference { get; set; }
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ValidatedAt { get; set; }
    public string? ValidatedBy { get; set; }
    public DateTime? RejectedAt { get; set; }
    public string? RejectedBy { get; set; }
    public string? RejectionReason { get; set; }
}
