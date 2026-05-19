import '../../../../../core/entities/entities.dart';
import '../../../../../core/utils/json_readers.dart';

class BlogModel {
  final String id;
  final String psychologistId;
  final String psychologistName;
  final String? psychologistAvatar;
  final String title;
  final String body;
  final String? category;
  final List<String> tags;
  final String status;
  final String? coverImageUrl;
  final int viewCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const BlogModel({
    required this.id,
    required this.psychologistId,
    required this.psychologistName,
    required this.psychologistAvatar,
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    required this.status,
    required this.coverImageUrl,
    required this.viewCount,
    required this.commentCount,
    required this.createdAt,
    required this.publishedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    final psychologist = JsonReaders.asMap(
      JsonReaders.readAny(json, ['psychologist', 'author']),
    );
    final psychologistUser = JsonReaders.asMap(
      JsonReaders.readAny(psychologist, ['user']),
    );

    final category = JsonReaders.readString(json, ['category']).trim();
    final coverImage =
        JsonReaders.readString(json, ['coverImageUrl', 'coverImage']).trim();
    final avatar = JsonReaders.readString(
      json,
      ['psychologistAvatar', 'psychologistAvatarUrl'],
      fallback: JsonReaders.readString(
        psychologist,
        ['avatarUrl', 'avatar', 'profilePicture'],
        fallback: JsonReaders.readString(
          psychologistUser,
          ['avatarUrl', 'avatar', 'profilePicture'],
        ),
      ),
    ).trim();

    final publishedAtRaw =
        JsonReaders.readString(json, ['publishedAt', 'published_at']).trim();

    return BlogModel(
      id: JsonReaders.readString(json, ['id', '_id', 'blogId']),
      psychologistId: JsonReaders.readString(
        json,
        ['psychologistId'],
        fallback: JsonReaders.readString(psychologist, ['id', '_id']),
      ),
      psychologistName: JsonReaders.readString(
        json,
        ['psychologistName'],
        fallback: JsonReaders.readString(
          psychologist,
          ['name', 'fullName'],
          fallback: JsonReaders.readString(
            psychologistUser,
            ['name', 'fullName'],
            fallback: 'MindZep Expert',
          ),
        ),
      ),
      psychologistAvatar: avatar.isEmpty ? null : avatar,
      title: JsonReaders.readString(json, ['title']),
      body: JsonReaders.readString(json, ['body', 'content']),
      category: category.isEmpty ? null : category,
      tags: JsonReaders.readStringList(json, ['tags']),
      status: JsonReaders.readString(json, ['status'], fallback: 'draft'),
      coverImageUrl: coverImage.isEmpty ? null : coverImage,
      viewCount: JsonReaders.readInt(json, ['viewCount', 'views']),
      commentCount: JsonReaders.readInt(json, ['commentCount', 'comments']),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
      publishedAt:
          publishedAtRaw.isEmpty ? null : DateTime.tryParse(publishedAtRaw),
    );
  }

  BlogEntity toEntity() {
    return BlogEntity(
      id: id,
      psychologistId: psychologistId,
      psychologistName: psychologistName,
      psychologistAvatar: psychologistAvatar,
      title: title,
      body: body,
      category: category?.trim().isNotEmpty == true ? category! : 'Other',
      tags: tags,
      coverImageUrl: coverImageUrl,
      status: _toBlogStatus(status),
      viewCount: viewCount,
      commentCount: commentCount,
      createdAt: createdAt,
      publishedAt: publishedAt,
    );
  }

  static BlogStatus _toBlogStatus(String value) {
    switch (value.toLowerCase()) {
      case 'underreview':
      case 'under_review':
        return BlogStatus.underReview;
      case 'published':
        return BlogStatus.published;
      case 'rejected':
        return BlogStatus.rejected;
      case 'draft':
      default:
        return BlogStatus.draft;
    }
  }
}

class CreateBlogRequest {
  final String title;
  final String body;
  final String? category;
  final List<String>? tags;

  const CreateBlogRequest({
    required this.title,
    required this.body,
    this.category,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
    };
  }
}

class UpdateBlogRequest {
  final String? title;
  final String? body;
  final String? category;
  final List<String>? tags;

  const UpdateBlogRequest({
    this.title,
    this.body,
    this.category,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
    };
  }
}

class BlogReviewRequest {
  final String? adminNotes;

  const BlogReviewRequest({this.adminNotes});

  Map<String, dynamic> toJson() {
    return {
      if (adminNotes != null) 'adminNotes': adminNotes,
    };
  }
}

class BlogRejectionRequest {
  final String rejectionReason;
  final String? adminNotes;

  const BlogRejectionRequest({
    required this.rejectionReason,
    this.adminNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'rejectionReason': rejectionReason,
      if (adminNotes != null) 'adminNotes': adminNotes,
    };
  }
}
