function createPostSearch(search) {
  const keyword = typeof search === 'string' ? search.trim().toLowerCase() : '';

  return p => !keyword || p.title.toLowerCase().includes(keyword)
    || p.content.toLowerCase().includes(keyword);
}

module.exports = createPostSearch;
