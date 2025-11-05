# 🌐 Giải pháp IP tĩnh/Domain cho ECS

## 📋 So sánh các giải pháp

### 1. ✅ Application Load Balancer (ALB) - KHUYẾN NGHỊ
**Chi phí:** ~$16/tháng  
**Ưu điểm:**
- DNS name cố định (không đổi)
- Dễ dàng gắn domain tùy chỉnh
- Hỗ trợ HTTPS/SSL
- Health check tự động
- Scale tốt cho production
- Blue-green deployment dễ dàng

**Nhược điểm:**
- Chi phí cao hơn
- Phức tạp hơn một chút

**Cách triển khai:**
```bash
# Bước 1: Tạo ALB module (đã tạo sẵn ở terraform/modules/alb/)

# Bước 2: Thêm vào main.tf
module "alb" {
  source = "../../modules/alb"
  
  name_prefix        = local.name_prefix
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = [aws_subnet.public.id]
  container_port     = 3000
}

# Bước 3: Update ECS service để dùng ALB
resource "aws_ecs_service" "app" {
  # ... existing config ...
  
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = 3000
  }
  
  # Remove assign_public_ip = true
}

# Bước 4: Terraform apply
cd terraform/environments/dev
terraform apply
```

**Sau khi deploy:**
- Access app qua ALB DNS: `http://nhaituvung-staging-alb-123456789.ap-southeast-1.elb.amazonaws.com`
- Gắn domain: Tạo CNAME record trỏ tới ALB DNS

---

### 2. ⚡ Elastic IP (EIP) - ĐƠN GIẢN NHẤT
**Chi phí:** FREE (nếu đang dùng) hoặc $3.6/tháng (nếu không attach vào EC2)  
**Ưu điểm:**
- IP tĩnh thực sự
- Chi phí thấp
- Đơn giản

**Nhược điểm:**
- Cần NAT Gateway (~$32/tháng) hoặc EC2 NAT instance
- Không scale tốt
- Không có health check tự động
- Phức tạp với Fargate

**KHÔNG KHUYẾN NGHỊ cho Fargate**

---

### 3. 🌍 CloudFront + Origin Domain - TỐI ƯU NHẤT
**Chi phí:** ~$1-5/tháng (tùy traffic)  
**Ưu điểm:**
- CDN toàn cầu (siêu nhanh)
- SSL miễn phí
- DDoS protection
- Cache tĩnh
- Chi phí thấp

**Nhược điểm:**
- Cần ALB hoặc public IP làm origin
- Setup phức tạp hơn

**Kết hợp tốt nhất: ALB + CloudFront + Custom Domain**

---

## 🚀 Hướng dẫn chi tiết cho từng giải pháp

### A. GIẢI PHÁP ĐƠN GIẢN: Chỉ dùng ALB

#### Bước 1: Thêm public subnet thứ 2 (ALB cần ít nhất 2 subnets)

```hcl
# terraform/environments/dev/main.tf

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-2"
  }
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
```

#### Bước 2: Thêm ALB module vào main.tf

```hcl
module "alb" {
  source = "../../modules/alb"
  
  name_prefix        = local.name_prefix
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = [aws_subnet.public.id, aws_subnet.public_2.id]
  container_port     = 3000
}
```

#### Bước 3: Update Security Group cho ECS

```hcl
resource "aws_security_group" "ecs" {
  # ... existing config ...

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [module.alb.alb_security_group_id]
  }
  
  # Remove ingress from 0.0.0.0/0
}
```

#### Bước 4: Update ECS Service

```hcl
resource "aws_ecs_service" "app" {
  name                               = "${local.name_prefix}-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true  # Vẫn cần để pull image từ ECR
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = 3000
  }

  depends_on = [module.alb]

  tags = {
    Name = "${local.name_prefix}-ecs-service"
  }
}
```

#### Bước 5: Add output

```hcl
# terraform/environments/dev/outputs.tf

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.alb.alb_dns_name}"
}
```

#### Bước 6: Apply

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

---

### B. GIẢI PHÁP ĐẦY ĐỦ: ALB + Domain + SSL

#### Bước 1: Mua domain (hoặc dùng domain có sẵn)
- Namecheap, GoDaddy, Route53, etc.

#### Bước 2: Tạo Hosted Zone trong Route53

```bash
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s) \
  --profile nhaituvung
```

#### Bước 3: Request SSL Certificate

```bash
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region ap-southeast-1 \
  --profile nhaituvung
```

#### Bước 4: Thêm DNS records để validate certificate

#### Bước 5: Update ALB với HTTPS listener

```hcl
module "alb" {
  source = "../../modules/alb"
  
  name_prefix        = local.name_prefix
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = [aws_subnet.public.id, aws_subnet.public_2.id]
  container_port     = 3000
  certificate_arn    = "arn:aws:acm:ap-southeast-1:xxx:certificate/xxx"  # Your cert ARN
}
```

#### Bước 6: Tạo Route53 record trỏ domain tới ALB

```hcl
resource "aws_route53_record" "app" {
  zone_id = "Z123456789"  # Your hosted zone ID
  name    = "api.yourdomain.com"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
```

---

## 💰 So sánh chi phí

| Giải pháp | Chi phí/tháng | Use case |
|-----------|---------------|----------|
| Chỉ ECS (IP đổi) | $15 | Development |
| ECS + ALB | $31 | Production nhỏ |
| ECS + ALB + CloudFront | $32-40 | Production có traffic |
| ECS + ALB + Route53 + ACM | $31.5 | Production với domain |

---

## 🎯 Khuyến nghị

### Nếu bạn đang development:
→ Giữ nguyên setup hiện tại (IP đổi), dùng script get-app-url.sh

### Nếu cần demo/test ổn định:
→ Dùng ALB (setup ở trên)

### Nếu production:
→ ALB + Custom Domain + SSL Certificate

---

## 📝 Bước tiếp theo

Bạn muốn tôi:
1. ✅ Setup ALB ngay bây giờ? (chi phí thêm $16/tháng)
2. ⏸️  Giữ nguyên như hiện tại (miễn phí)?
3. 🚀 Setup full: ALB + Domain + SSL?

Cho tôi biết bạn chọn option nào!
