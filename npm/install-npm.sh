#!/bin/bash

################################################################################
# Nginx Proxy Manager 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Docker 네트워크 생성 (없는 경우)
# 4. docker-compose.yml 파일 자동 생성
# 5. Nginx Proxy Manager 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/npm/install-npm.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/npm/install-npm.sh
#      chmod +x install-npm.sh
#      sudo ./install-npm.sh
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
    print_header "Nginx Proxy Manager 설정 정보 입력"
    
    # 컨테이너 이름
    echo -e "${CYAN}컨테이너 이름을 입력하세요 (기본값: npmjc):${NC}"
    read -p "> " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-npmjc}
    print_success "컨테이너 이름: $CONTAINER_NAME"
    
    # 네트워크 이름
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크 이름: $NETWORK_NAME"
    
    # 관리 페이지 포트
    echo ""
    echo -e "${CYAN}관리 페이지 포트를 입력하세요 (기본값: 7081):${NC}"
    print_info "이 포트로 Nginx Proxy Manager 관리 페이지에 접속합니다."
    read -p "> " ADMIN_PORT
    ADMIN_PORT=${ADMIN_PORT:-7081}
    
    # 포트 유효성 검사
    if ! [[ "$ADMIN_PORT" =~ ^[0-9]+$ ]] || [ "$ADMIN_PORT" -lt 1 ] || [ "$ADMIN_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    
    # 포트 사용 중 확인
    if netstat -tuln 2>/dev/null | grep -q ":${ADMIN_PORT} " || ss -tuln 2>/dev/null | grep -q ":${ADMIN_PORT} "; then
        print_warning "포트 $ADMIN_PORT 가 이미 사용 중입니다."
        read -p "다른 포트를 사용하시겠습니까? (y/N): " CHANGE_PORT
        if [ "$CHANGE_PORT" = "y" ] || [ "$CHANGE_PORT" = "Y" ]; then
            echo -e "${CYAN}새로운 포트를 입력하세요:${NC}"
            read -p "> " ADMIN_PORT
            if ! [[ "$ADMIN_PORT" =~ ^[0-9]+$ ]] || [ "$ADMIN_PORT" -lt 1 ] || [ "$ADMIN_PORT" -gt 65535 ]; then
                print_error "유효하지 않은 포트 번호입니다."
                exit 1
            fi
        fi
    fi
    
    print_success "관리 페이지 포트: $ADMIN_PORT"
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "컨테이너 이름  : $CONTAINER_NAME"
    echo "네트워크 이름  : $NETWORK_NAME"
    echo "관리 페이지 포트: $ADMIN_PORT"
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
    
    # 필요한 디렉토리 생성
    mkdir -p data
    mkdir -p letsencrypt
    
    print_success "디렉토리 생성 완료"
    echo "  - data/         (Nginx Proxy Manager 데이터)"
    echo "  - letsencrypt/  (SSL 인증서)"
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
# Nginx Proxy Manager
################################################################################
# 웹 기반 리버스 프록시 관리 도구
# 
# 기본 접속 정보:
#   - 관리 페이지: http://YOUR_SERVER_IP:${ADMIN_PORT}
#   - 기본 이메일: admin@example.com
#   - 기본 비밀번호: changeme
#   
# 최초 로그인 후 반드시 비밀번호를 변경하세요!
################################################################################

services:
  ${CONTAINER_NAME}:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    network_mode: ${NETWORK_NAME}
    environment:
      # 타임존 설정
      TZ: "Asia/Seoul"
      
    ports:
      # HTTP 포트
      - '80:80'
      
      # 관리 페이지 포트 (외부 접속용)
      - '${ADMIN_PORT}:81'
      
      # HTTPS 포트
      - '443:443'
      
    volumes:
      # Nginx Proxy Manager 데이터 저장 경로
      - ./data:/data
      
      # Let's Encrypt SSL 인증서 저장 경로
      - ./letsencrypt:/etc/letsencrypt
EOF

    print_success "docker-compose.yml 파일 생성 완료"
}

################################################################################
# 설정 정보 저장
################################################################################
save_configuration() {
    print_header "설정 정보 저장"
    
    # 설정 정보 파일 생성
    cat > .npm-config << EOF
# Nginx Proxy Manager 설정 정보
# 생성일: $(date)

CONTAINER_NAME=$CONTAINER_NAME
NETWORK_NAME=$NETWORK_NAME
ADMIN_PORT=$ADMIN_PORT

# 관리 페이지 접속: http://YOUR_SERVER_IP:${ADMIN_PORT}

# 관리 페이지 기본 로그인 정보
# 이메일: admin@example.com
# 비밀번호: changeme
# ⚠️  최초 로그인 후 반드시 변경하세요!
EOF
    
    chmod 600 .npm-config
    
    print_success "설정 정보가 .npm-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "Nginx Proxy Manager를 시작합니다..."
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
    print_info "컨테이너 상태를 확인하는 중..."
    sleep 3
    
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
    print_success "Nginx Proxy Manager 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ docker-compose.yml    (Docker Compose 설정 파일)"
    echo "  ✓ .npm-config           (설정 정보 백업)"
    echo "  ✓ data/                 (데이터 저장 디렉토리)"
    echo "  ✓ letsencrypt/          (SSL 인증서 디렉토리)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  컨테이너 이름  : $CONTAINER_NAME"
    echo "  네트워크 이름  : $NETWORK_NAME"
    echo "  관리 페이지 포트: $ADMIN_PORT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 접속 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  관리 페이지: http://${SERVER_IP}:${ADMIN_PORT}"
    echo ""
    echo "  기본 로그인 정보:"
    echo "    이메일: admin@example.com"
    echo "    비밀번호: changeme"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 최초 로그인 후 반드시 다음 작업을 수행하세요:"
    echo "    1. 비밀번호 변경"
    echo "    2. 이메일 주소 변경"
    echo "    3. 관리자 계정 이름 변경 (선택사항)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • 서비스 시작: docker compose up -d"
    echo "  • 컨테이너 상태: docker compose ps"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 다음 단계"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. 브라우저에서 http://${SERVER_IP}:${ADMIN_PORT} 접속"
    echo "  2. 기본 계정으로 로그인"
    echo "  3. 비밀번호 및 이메일 변경"
    echo "  4. Proxy Host 추가하여 도메인 연결"
    echo "  5. SSL 인증서 발급 (Let's Encrypt)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 공식 문서: https://nginxproxymanager.com/guide/"
    echo "  • GitHub: https://github.com/NginxProxyManager/nginx-proxy-manager"
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
    echo "║          Nginx Proxy Manager 자동 설치 스크립트                ║"
    echo "║          리버스 프록시 관리 도구                               ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker                # 1. Docker 확인
    get_user_input              # 2. 사용자 입력
    check_and_create_network    # 3. 네트워크 확인 및 생성
    create_directories          # 4. 디렉토리 생성
    generate_docker_compose     # 5. docker-compose.yml 생성
    save_configuration          # 6. 설정 정보 저장
    start_service               # 7. 서비스 시작
    final_summary               # 8. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
