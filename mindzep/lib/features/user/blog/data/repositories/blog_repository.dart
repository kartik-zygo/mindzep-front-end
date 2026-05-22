import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/blog_models.dart';

class BlogRepository {
  BlogRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<BlogModel>> listPublishedBlogs({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<List<BlogModel>>(
      ApiEndpoints.blogs,
      queryParameters: {'page': page, 'limit': limit},
      parser: (json) => JsonReaders.asMapList(json).map(BlogModel.fromJson).toList(),
    );
  }

  Future<BlogModel> getBlogById(String blogId) {
    return _dioClient.get<BlogModel>(
      ApiEndpoints.blogById(blogId),
      parser: (json) => BlogModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<List<BlogModel>> listMyBlogs({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<List<BlogModel>>(
      ApiEndpoints.blogsMy,
      queryParameters: {'page': page, 'limit': limit},
      parser: (json) => JsonReaders.asMapList(json).map(BlogModel.fromJson).toList(),
    );
  }

  Future<BlogModel> createBlog(CreateBlogRequest request) {
    return _dioClient.post<BlogModel>(
      ApiEndpoints.blogs,
      data: request.toJson(),
      parser: (json) {
        final map = JsonReaders.asMap(json);
        // Response: { data: { blog: { _id: ... } } } — unwrap nested 'blog' key
        final blogMap = map.containsKey('blog') ? JsonReaders.asMap(map['blog']) : map;
        return BlogModel.fromJson(blogMap);
      },
    );
  }

  Future<BlogModel> updateBlog(String blogId, UpdateBlogRequest request) {
    return _dioClient.put<BlogModel>(
      ApiEndpoints.blogById(blogId),
      data: request.toJson(),
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final blogMap = map.containsKey('blog') ? JsonReaders.asMap(map['blog']) : map;
        return BlogModel.fromJson(blogMap);
      },
    );
  }

  Future<void> submitBlog(String blogId) {
    return _dioClient.post<void>(
      ApiEndpoints.blogSubmit(blogId),
      parser: (_) => null,
    );
  }

  Future<void> deleteBlog(String blogId) {
    return _dioClient.delete<void>(
      ApiEndpoints.blogById(blogId),
      parser: (_) => null,
    );
  }

  Future<List<BlogModel>> listAdminAllBlogs({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<List<BlogModel>>(
      ApiEndpoints.blogsAdminAll,
      queryParameters: {'page': page, 'limit': limit},
      parser: (json) {
        final m = JsonReaders.asMap(json);
        final list = m.containsKey('blogs') ? m['blogs'] : json;
        return JsonReaders.asMapList(list).map(BlogModel.fromJson).toList();
      },
    );
  }

  Future<List<BlogModel>> listAdminSubmittedBlogs({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<List<BlogModel>>(
      ApiEndpoints.blogsAdminSubmitted,
      queryParameters: {'page': page, 'limit': limit},
      parser: (json) {
        final m = JsonReaders.asMap(json);
        final list = m.containsKey('blogs') ? m['blogs'] : json;
        return JsonReaders.asMapList(list).map(BlogModel.fromJson).toList();
      },
    );
  }

  Future<void> reviewBlog(String blogId, BlogReviewRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.blogReview(blogId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> approveBlog(String blogId, BlogReviewRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.blogsAdminApprove(blogId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> rejectBlog(String blogId, BlogRejectionRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.blogsAdminReject(blogId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }
}
