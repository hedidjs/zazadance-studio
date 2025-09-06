/// Generic pagination result wrapper
class PaginationResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  const PaginationResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasMore = (currentPage * pageSize) < totalCount;

  /// Create empty pagination result
  factory PaginationResult.empty() {
    return const PaginationResult(
      items: [],
      totalCount: 0,
      currentPage: 0,
      pageSize: 20,
    );
  }

  /// Calculate total number of pages
  int get totalPages => (totalCount / pageSize).ceil();

  /// Check if this is the first page
  bool get isFirstPage => currentPage <= 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= totalPages;

  /// Get next page number (null if no next page)
  int? get nextPage => hasMore ? currentPage + 1 : null;

  /// Get previous page number (null if no previous page)
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  /// Create a copy with different items (useful for combining pages)
  PaginationResult<T> copyWith({
    List<T>? items,
    int? totalCount,
    int? currentPage,
    int? pageSize,
  }) {
    return PaginationResult<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Combine this page with items from another page (useful for infinite scroll)
  PaginationResult<T> appendPage(PaginationResult<T> nextPage) {
    return PaginationResult<T>(
      items: [...items, ...nextPage.items],
      totalCount: nextPage.totalCount, // Use the latest count
      currentPage: nextPage.currentPage,
      pageSize: pageSize,
    );
  }

  @override
  String toString() {
    return 'PaginationResult(items: ${items.length}, '
           'totalCount: $totalCount, currentPage: $currentPage, '
           'pageSize: $pageSize, hasMore: $hasMore)';
  }
}

/// Pagination parameters for queries
class PaginationParams {
  final int page;
  final int pageSize;
  final int offset;

  const PaginationParams({
    this.page = 1,
    this.pageSize = 20,
  }) : offset = (page - 1) * pageSize;

  /// Create pagination params for next page
  PaginationParams nextPage() {
    return PaginationParams(page: page + 1, pageSize: pageSize);
  }

  /// Create pagination params for previous page
  PaginationParams previousPage() {
    return PaginationParams(
      page: page > 1 ? page - 1 : 1, 
      pageSize: pageSize,
    );
  }

  /// Create pagination params for specific page
  PaginationParams goToPage(int targetPage) {
    return PaginationParams(
      page: targetPage > 0 ? targetPage : 1,
      pageSize: pageSize,
    );
  }

  @override
  String toString() {
    return 'PaginationParams(page: $page, pageSize: $pageSize, offset: $offset)';
  }
}