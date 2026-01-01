#!/bin/bash

################################################################################
# Nginx + SSH 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Docker 네트워크 생성 (없는 경우)
# 4. Dockerfile 자동 생성 (Ubuntu + Nginx + SSH)
# 5. Docker 이미지 빌드
# 6. docker-compose.yml 파일 자동 생성
# 7. Nginx + SSH 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/nginx-ssh/install-nginx-ssh.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/registry/install-nginx-ssh.sh
#      chmod +x install-nginx-ssh.sh
#      sudo ./install-nginx-ssh.sh
#
################################################################################

set -e  # 에러 발생 시 스크립트 중단

################################################################################
# 색상 정의
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# 출력 함수들
################################################################################
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

################################################################################
# Docker 및 Docker Compose 확인
################################################################################
check_docker() {
    print_header "시스템 요구사항 확인"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되어 있지 않습니다."
        echo ""
        print_info "Docker를 먼저 설치해주세요:"
        echo "  curl -fsSL https://get.docker.com | sudo bash"
        exit 1
    fi
    
    print_success "Docker 설치 확인 완료: $(docker --version)"
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose가 설치되어 있지 않습니다."
        exit 1
    fi
    
    print_success "Docker Compose 설치 확인 완료"
}

################################################################################
# 사용자 입력 받기
################################################################################
get_user_input() {
    print_header "Nginx + SSH 설정 정보 입력"
    
    # 컨테이너 이름
    echo -e "${CYAN}Docker 컨테이너 이름을 입력하세요 (기본값: nginx-ssh):${NC}"
    read -p "> " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-nginx-ssh}
    print_success "컨테이너 이름: $CONTAINER_NAME"
    
    # 네트워크 이름
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크 이름: $NETWORK_NAME"
    
    # SSH 포트
    echo ""
    echo -e "${CYAN}SSH 포트를 입력하세요 (기본값: 2222):${NC}"
    read -p "> " SSH_PORT
    SSH_PORT=${SSH_PORT:-2222}
    
    # 포트 유효성 검사
    if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    print_success "SSH 포트: $SSH_PORT"
    
    # HTTP 포트
    echo ""
    echo -e "${CYAN}HTTP 포트를 입력하세요 (기본값: 80):${NC}"
    read -p "> " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-80}
    
    # 포트 유효성 검사
    if ! [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] || [ "$HTTP_PORT" -lt 1 ] || [ "$HTTP_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    print_success "HTTP 포트: $HTTP_PORT"
    
    # SSH 사용자 이름
    echo ""
    echo -e "${CYAN}SSH 사용자 이름을 입력하세요 (기본값: admin):${NC}"
    read -p "> " SSH_USER
    SSH_USER=${SSH_USER:-admin}
    print_success "SSH 사용자: $SSH_USER"
    
    # SSH 비밀번호
    echo ""
    print_info "SSH 비밀번호를 설정합니다."
    echo ""
    while true; do
        read -sp "SSH 비밀번호: " SSH_PASSWORD
        echo ""
        
        if [ -z "$SSH_PASSWORD" ]; then
            print_error "비밀번호를 입력해주세요."
            continue
        fi
        
        read -sp "SSH 비밀번호 확인: " SSH_PASSWORD_CONFIRM
        echo ""
        
        if [ "$SSH_PASSWORD" != "$SSH_PASSWORD_CONFIRM" ]; then
            print_error "비밀번호가 일치하지 않습니다."
            continue
        fi
        
        break
    done
    print_success "SSH 비밀번호 설정 완료"
    
    # 타임존 설정
    echo ""
    echo -e "${CYAN}서버 타임존을 입력하세요 (기본값: Asia/Seoul):${NC}"
    read -p "> " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Seoul}
    print_success "타임존: $TIMEZONE"
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "컨테이너 이름    : $CONTAINER_NAME"
    echo "네트워크 이름    : $NETWORK_NAME"
    echo "SSH 포트        : $SSH_PORT"
    echo "HTTP 포트       : $HTTP_PORT"
    echo "SSH 사용자      : $SSH_USER"
    echo "타임존          : $TIMEZONE"
    echo "HTML 경로       : html/"
    echo ""
    read -p "이 설정으로 진행하시겠습니까? (y/N): " CONFIRM
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_warning "설정을 취소했습니다."
        exit 0
    fi
}

################################################################################
# Docker 네트워크 확인 및 생성
################################################################################
check_and_create_network() {
    print_header "Docker 네트워크 확인"
    
    # 네트워크 존재 확인
    if docker network ls | grep -q "\s${NETWORK_NAME}\s"; then
        print_success "'$NETWORK_NAME' 네트워크가 이미 존재합니다."
    else
        print_warning "'$NETWORK_NAME' 네트워크가 존재하지 않습니다."
        print_info "'$NETWORK_NAME' 네트워크를 생성합니다..."
        docker network create --driver=bridge $NETWORK_NAME
        print_success "'$NETWORK_NAME' 네트워크가 생성되었습니다."
    fi
}

################################################################################
# 디렉토리 생성
################################################################################
create_directories() {
    print_header "디렉토리 구조 생성"
    
    # HTML 디렉토리 생성
    mkdir -p html
    
    # 기본 index.html 생성
    if [ ! -f html/index.html ]; then
        cat > ./html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nginx</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
        }
        p {
            font-size: 1.2em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Nginx + SSH 서버가 실행 중입니다!</h1>
        <p>HTML 파일을 ~/html/ 디렉토리에 업로드하세요.</p>
    </div>
</body>
</html>
EOF
    fi
    
    # 현재 로그인된 사용자 확인
    REAL_USER=${SUDO_USER:-$USER}
    
    # 소유자를 실제 사용자로 변경
    chown -R $REAL_USER:$REAL_USER html
    
    # index.html도 소유자 변경
    chown $REAL_USER:$REAL_USER html/index.html
    
    print_success "디렉토리 생성 완료"
    echo "  - ~/html/ (웹 루트 디렉토리, 소유자: $REAL_USER)"
}

################################################################################
# Dockerfile 생성
################################################################################
generate_dockerfile() {
    print_header "Dockerfile 생성"
    
    # 기존 파일이 있으면 백업
    if [ -f "Dockerfile" ]; then
        print_warning "기존 Dockerfile을 백업합니다."
        mv Dockerfile Dockerfile.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Dockerfile 생성
    cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

# 기본 패키지 업데이트 및 설치
RUN apt-get update && apt-get install -y \
    nginx \
    openssh-server \
    sudo \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# SSH 디렉토리 생성
RUN mkdir /var/run/sshd

# SSH 설정
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers *" >> /etc/ssh/sshd_config

# Nginx 설정
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# 웹 루트 디렉토리 생성
RUN mkdir -p /var/www/html

# 기본 Nginx 설정
RUN rm -f /etc/nginx/sites-enabled/default
COPY default.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# 시작 스크립트 복사
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 포트 노출
EXPOSE 80 22

# 엔트리포인트 설정
ENTRYPOINT ["/entrypoint.sh"]
EOF
    
    print_success "Dockerfile 생성 완료"
}

################################################################################
# Nginx 설정 파일 생성
################################################################################
generate_nginx_config() {
    print_header "Nginx 설정 파일 생성"
    
    cat > default.conf << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    # 정적 파일 캐시(선택)
    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico)$ {
      try_files $uri =404;
      add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # SPA history fallback
    location / {
      try_files $uri $uri/ /index.html;
    }

    # 로그 설정
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # 업로드 제한
    client_max_body_size 100m;
}
EOF
    
    print_success "Nginx 설정 파일 생성 완료"
}

################################################################################
# 엔트리포인트 스크립트 생성
################################################################################
generate_entrypoint() {
    print_header "엔트리포인트 스크립트 생성"
    
    cat > entrypoint.sh << 'ENTRYPOINT_EOF'
#!/bin/bash

# 타임존 설정
if [ ! -z "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# SSH 사용자 생성
if [ ! -z "$SSH_USER" ] && [ ! -z "$SSH_PASSWORD" ]; then
    # 사용자가 이미 존재하는지 확인
    if ! id "$SSH_USER" &>/dev/null; then
        useradd -m -s /bin/bash $SSH_USER
        echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
        
        # sudo 권한 부여
        usermod -aG sudo $SSH_USER
        
        # 사용자 홈 디렉토리에 html 링크 생성
        ln -sf /var/www/html /home/$SSH_USER/html
        
        echo "SSH 사용자 '$SSH_USER' 생성 완료"
    fi
fi

# SSH 호스트 키 생성
ssh-keygen -A

# SSH 서비스 시작
/usr/sbin/sshd

# Nginx 시작 (포그라운드)
exec nginx
ENTRYPOINT_EOF
    
    chmod +x entrypoint.sh
    print_success "엔트리포인트 스크립트 생성 완료"
}

################################################################################
# Docker 이미지 빌드
################################################################################
build_docker_image() {
    print_header "Docker 이미지 빌드"
    
    IMAGE_NAME="nginx-ssh-custom"
    IMAGE_TAG="latest"
    
    print_info "Docker 이미지를 빌드합니다... (시간이 소요될 수 있습니다)"
    echo ""
    
    if docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .; then
        print_success "Docker 이미지 빌드 완료: ${IMAGE_NAME}:${IMAGE_TAG}"
    else
        print_error "Docker 이미지 빌드에 실패했습니다."
        exit 1
    fi
}

################################################################################
# docker-compose.yml 파일 생성
################################################################################
generate_docker_compose() {
    print_header "docker-compose.yml 파일 생성"
    
    # 기존 파일이 있으면 백업
    if [ -f "docker-compose.yml" ]; then
        print_warning "기존 docker-compose.yml 파일을 백업합니다."
        mv docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # docker-compose.yml 파일 작성
    cat > docker-compose.yml << EOF
################################################################################
# Nginx + SSH Server
################################################################################
# Nginx 웹 서버와 SSH 접속이 가능한 환경
#
# 접속 정보:
# - HTTP: http://YOUR_SERVER_IP:${HTTP_PORT}
# - SSH: ssh ${SSH_USER}@YOUR_SERVER_IP -p ${SSH_PORT}
# - HTML 경로: ~/html
#
################################################################################

services:
  # Nginx + SSH 서버
  ${CONTAINER_NAME}:
    image: nginx-ssh-custom:latest
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    environment:
      # 타임존 설정
      - TZ=${TIMEZONE}
      # SSH 사용자 설정
      - SSH_USER=${SSH_USER}
      - SSH_PASSWORD=${SSH_PASSWORD}
    ports:
      # HTTP 포트
      - '${HTTP_PORT}:80'
      # SSH 포트
      - '${SSH_PORT}:22'
    volumes:
      # 웹 루트 디렉토리
      - ./html:/var/www/html
    networks:
      - ${NETWORK_NAME}

################################################################################
# 네트워크 설정
################################################################################
networks:
  ${NETWORK_NAME}:
    external: true
EOF
    
    print_success "docker-compose.yml 파일 생성 완료"
}

################################################################################
# 설정 정보 저장
################################################################################
save_configuration() {
    print_header "설정 정보 저장"
    
    # 설정 정보 파일 생성 (비밀번호 제외)
    cat > .nginx-ssh-config << EOF
# Nginx + SSH 설정 정보
# 생성일: $(date)

# 컨테이너 정보
CONTAINER_NAME=$CONTAINER_NAME
NETWORK_NAME=$NETWORK_NAME

# 포트 정보
SSH_PORT=$SSH_PORT
HTTP_PORT=$HTTP_PORT

# SSH 사용자 정보
SSH_USER=$SSH_USER

# 타임존
TIMEZONE=$TIMEZONE

# HTML 경로
HTML_PATH=./html

# Docker 이미지
IMAGE_NAME=nginx-ssh-custom:latest

# 접속 정보:
# HTTP: http://YOUR_SERVER_IP:${HTTP_PORT}
# SSH: ssh ${SSH_USER}@YOUR_SERVER_IP -p ${SSH_PORT}
EOF
    
    chmod 600 .nginx-ssh-config
    print_success "설정 정보가 .nginx-ssh-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "Nginx + SSH 서버를 시작합니다..."
    echo ""
    
    # Docker Compose로 서비스 시작
    if docker compose up -d; then
        print_success "서비스가 성공적으로 시작되었습니다!"
    else
        print_error "서비스 시작에 실패했습니다."
        print_info "로그를 확인하세요: docker compose logs"
        exit 1
    fi
    
    echo ""
    print_info "컨테이너가 초기화되는 중입니다... (10초 대기)"
    sleep 10
    
    # 컨테이너 상태 확인
    if docker ps | grep -q $CONTAINER_NAME; then
        print_success "컨테이너가 정상적으로 실행 중입니다."
    else
        print_warning "컨테이너 상태를 확인할 수 없습니다."
        print_info "다음 명령어로 확인하세요: docker compose ps"
    fi
}

################################################################################
# 서버 IP 주소 가져오기
################################################################################
get_server_ip() {
    # 공인 IP 주소 가져오기 (여러 방법 시도)
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
}

################################################################################
# 최종 요약 및 안내
################################################################################
final_summary() {
    print_header "설치 완료!"
    
    get_server_ip
    
    echo ""
    print_success "Nginx + SSH 서버 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Dockerfile (Docker 이미지 빌드 파일)"
    echo "  ✓ default.conf (Nginx 설정)"
    echo "  ✓ entrypoint.sh (시작 스크립트)"
    echo "  ✓ docker-compose.yml (Docker Compose 설정)"
    echo "  ✓ .nginx-ssh-config (설정 정보)"
    echo "  ✓ html/ (웹 루트 디렉토리)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  컨테이너 이름    : $CONTAINER_NAME"
    echo "  네트워크        : $NETWORK_NAME"
    echo "  SSH 포트        : $SSH_PORT"
    echo "  HTTP 포트       : $HTTP_PORT"
    echo "  SSH 사용자      : $SSH_USER"
    echo "  타임존          : $TIMEZONE"
    echo "  HTML 경로       : html/"
    echo "  이미지          : nginx-ssh-custom:latest"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 접속 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📌 HTTP 접속:"
    echo "     http://${SERVER_IP}:${HTTP_PORT}"
    echo ""
    echo "  📌 SSH 접속:"
    echo "     ssh ${SSH_USER}@${SERVER_IP} -p ${SSH_PORT}"
    echo "     비밀번호: (설정한 비밀번호)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 사용 방법"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  # SSH로 접속"
    echo "  ssh ${SSH_USER}@${SERVER_IP} -p ${SSH_PORT}"
    echo ""
    echo "  # 접속 후 html 디렉토리 확인"
    echo "  cd ~/html"
    echo "  ls -la"
    echo ""
    echo "  # HTML 파일 업로드 (SCP 사용)"
    echo "  scp -P ${SSH_PORT} index.html ${SSH_USER}@${SERVER_IP}:~/html/"
    echo ""
    echo "  # HTML 파일 업로드 (SFTP 사용)"
    echo "  sftp -P ${SSH_PORT} ${SSH_USER}@${SERVER_IP}"
    echo "  put index.html html/"
    echo ""
    echo "  # 웹 브라우저로 확인"
    echo "  http://${SERVER_IP}:${HTTP_PORT}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • 컨테이너 상태: docker compose ps"
    echo "  • 컨테이너 접속: docker exec -it ${CONTAINER_NAME} bash"
    echo "  • 이미지 재빌드: docker build -t nginx-ssh-custom:latest ."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️ 보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 다음 보안 작업을 수행하세요:"
    echo "  1. 강력한 SSH 비밀번호 사용"
    echo "  2. 방화벽 설정 (신뢰할 수 있는 IP만 SSH 접근 허용)"
    echo "  3. SSH 키 인증 사용 권장"
    echo "  4. 정기적인 비밀번호 변경"
    echo "  5. 디스크 공간 모니터링"
    echo "  6. 정기적인 보안 업데이트"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Nginx 문서: https://nginx.org/en/docs/"
    echo "  • Docker 문서: https://docs.docker.com/"
    echo "  • OpenSSH 문서: https://www.openssh.com/manual.html"
    echo ""
    print_success "설치 스크립트를 완료했습니다!"
}

################################################################################
# 메인 함수
################################################################################
main() {
    clear
    
    # 헤더 출력
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║         Nginx + SSH 자동 설치 스크립트                        ║"
    echo "║         Web Server with SSH Access                            ║"
    echo "║         (Custom Dockerfile Build)                             ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker              # 1. Docker 확인
    get_user_input           # 2. 사용자 입력
    check_and_create_network # 3. 네트워크 확인 및 생성
    create_directories       # 4. 디렉토리 생성
    generate_dockerfile      # 5. Dockerfile 생성
    generate_nginx_config    # 6. Nginx 설정 파일 생성
    generate_entrypoint      # 7. 엔트리포인트 스크립트 생성
    build_docker_image       # 8. Docker 이미지 빌드
    generate_docker_compose  # 9. docker-compose.yml 생성
    save_configuration       # 10. 설정 정보 저장
    start_service           # 11. 서비스 시작
    final_summary           # 12. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
