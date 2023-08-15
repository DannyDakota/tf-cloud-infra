resource "aws_s3_bucket" "aws_s3_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.aws_s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.aws_s3_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject", "s3:ListBucket"],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.aws_s3_bucket.arn,
          "${aws_s3_bucket.aws_s3_bucket.arn}/*",
        ],
        Principal = "*"
      },
    ],
  })
}


resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.aws_s3_bucket.id

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "POST"]
    max_age_seconds = 3000
    allowed_headers = ["Authorization"]
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.aws_s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.aws_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.aws_s3_bucket.id
  acl    = "public-read"
}

resource "null_resource" "build_react_app" {
  provisioner "local-exec" {
    command = <<EOF
        cd frontend && npm run build
        EOF

  }
}

resource "aws_s3_object" "app_files" {
  bucket = aws_s3_bucket.aws_s3_bucket.id
  key    = "static/index.html"
  source = "./frontend/build/index.html"
  etag   = filemd5("./frontend/build/index.html")

  depends_on = [null_resource.build_react_app]
}


resource "null_resource" "upload_react_files" {

  provisioner "local-exec" {
    command = <<EOF
        aws s3 sync ./frontend/build/ "s3://${var.bucket_name}"
        EOF

  }
  depends_on = [aws_s3_object.app_files, aws_s3_bucket.aws_s3_bucket]
}

