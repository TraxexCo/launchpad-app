enum ContractStatus {
  funded,
  inProgress,
  submitted,
  revisionRequested,
  completed,
  cancelled,
  disputed;

  static ContractStatus? parse(String value) => switch (value) {
    'funded' => funded,
    'in_progress' => inProgress,
    'submitted' => submitted,
    'revision_requested' => revisionRequested,
    'completed' => completed,
    'cancelled' => cancelled,
    'disputed' => disputed,
    _ => null,
  };
}

class ContractLifecycle {
  static bool canStart(String status) =>
      ContractStatus.parse(status) == ContractStatus.funded;

  static bool canSubmit(String status) {
    final parsed = ContractStatus.parse(status);
    return parsed == ContractStatus.inProgress ||
        parsed == ContractStatus.revisionRequested;
  }

  static bool canReview(String status) =>
      ContractStatus.parse(status) == ContractStatus.submitted;

  static bool canCancel({required String status, required bool funded}) {
    final parsed = ContractStatus.parse(status);
    return !funded &&
        parsed != null &&
        parsed != ContractStatus.completed &&
        parsed != ContractStatus.cancelled &&
        parsed != ContractStatus.disputed;
  }

  static bool canDispute(String status) {
    final parsed = ContractStatus.parse(status);
    return parsed != null &&
        parsed != ContractStatus.completed &&
        parsed != ContractStatus.cancelled &&
        parsed != ContractStatus.disputed;
  }
}
