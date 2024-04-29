class SearchData implements Comparable<SearchData>{
  final String index;
  final String content;

  const SearchData(this.index, this.content);

  int compareTo(SearchData other) => index.compareTo(other.index);
}