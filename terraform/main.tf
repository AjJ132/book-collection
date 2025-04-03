terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Create the Amplify app
resource "aws_amplify_app" "nextjs_app" {
  name = "book-collection"
  
  # GitHub source repository
  repository = "https://github.com/YOUR_GITHUB_USERNAME/book-collection"
  
  # For private repositories, use access_token
  # access_token = var.github_access_token
  
  # Build specification for Next.js
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .next/cache/**/*
  EOT
  
  # Environment variables
  environment_variables = {
    NODE_ENV = "production"
  }
  
  # For Next.js SSR support
  platform = "WEB_COMPUTE"
  
  # Configure rewrites and redirects for Next.js routing
  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }
  
  # Add additional rules for API routes if needed
  custom_rule {
    source = "/api/<*>"
    status = "200"
    target = "/api/<*>"
  }
}

# Create a branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.nextjs_app.id
  branch_name = "main"  # Change to match your main branch name
  
  # Enable auto-build
  enable_auto_build = true
  
  # Stage specific environment variables (if needed)
  environment_variables = {
    DATABASE_URL = "postgresql://dba:Aj5539320484$@prism-db.c3c8k0gyys4y.us-east-1.rds.amazonaws.com:5432/books"
  }
}

# Outputs
output "amplify_app_id" {
  value = aws_amplify_app.nextjs_app.id
}

output "amplify_default_domain" {
  value = aws_amplify_app.nextjs_app.default_domain
}

output "amplify_app_url" {
  value = "${aws_amplify_branch.main.branch_name}.${aws_amplify_app.nextjs_app.default_domain}"
}