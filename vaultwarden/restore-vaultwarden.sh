#!/bin/bash

################################################################################
# Vaultwarden 재해 복구 스크립트
################################################################################
# 이 스크립트는 Google Drive 백업에서 Vaultwarden을 복구합니다.
#
# 사용 방법:
#   1. 원라인 복구:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/restore-vaultwarden.sh | bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vaultwarden/restore-vaultwarden.sh
#      chmod +x restore-vaultwarden.sh
#      ./restore-vaultwarden.sh
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ $1${NC}"; }
print_step() { echo -e "${PURPLE}➜ $1${NC}"; }

check_docker() {
    print_header "시스템 요구사항 확인"
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되어 있지 않습니다."
        exit 1
    fi
    print_success "Docker 설치 확인 완료"
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose가 설치되어 있지 않습니다."
        exit 1
    fi
    print_success "Docker Compose 설치 확인 완료"
}

check_working_directory() {
    print_header "작업 디렉토리 확인"
    echo "현재 디렉토리: $(pwd)"
    if [ -f "docker-compose.yml" ] || [ -d "vaultwarden-data" ]; then
        print_warning "기존 Vaultwarden 관련 파일이 존재합니다."
        read -p "덮어쓰시겠습니까? (y/N): " OVERWRITE
        if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
            exit 0
        fi
        BACKUP_DIR="backup-$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        [ -f "docker-compose.yml" ] && mv docker-compose.yml "$BACKUP_DIR/"
        [ -d "vaultwarden-data" ] && mv vaultwarden-data "$BACKUP_DIR/"
        [ -d "rclone-config" ] && mv rclone-config "$BACKUP_DIR/"
        print_success "기존 파일이 $BACKUP_DIR/ 에 백업되었습니다."
    fi
}

create_directories() {
    print_header "디렉토리 구조 생성"
    mkdir -p vaultwarden-data rclone-config backup-logs
    print_success "디렉토리 생성 완료"
}

setup_rclone_gdrive() {
    print_header "Rclone Google Drive 설정"
    print_info "Google Drive 백업에 접근하기 위해 Rclone을 설정합니다."
    print_warning "Google 계정 인증이 필요합니다."
    echo ""
    read -p "계속하려면 엔터를 누르세요..."
    docker run --rm -it -v $(pwd)/rclone-config:/config/rclone rclone/rclone config
}

restore_rclone_config() {
    print_header "Rclone 설정 파일 복원"
    echo -e "${CYAN}Google Drive 백업 루트 폴더명을 입력하세요:${NC}"
    read -p "> " RCLONE_ROOT
    while [ -z "$RCLONE_ROOT" ]; do
        print_warning "폴더명을 입력해주세요."
        read -p "> " RCLONE_ROOT
    done
    
    print_step "백업 파일 확인 중..."
    BACKUP_CHECK=$(docker run --rm -v $(pwd)/rclone-config:/config/rclone rclone/rclone ls gdrive:$RCLONE_ROOT/rclone-config 2>&1)
    
    if echo "$BACKUP_CHECK" | grep -q "rclone.conf"; then
        print_success "백업 파일을 찾았습니다."
        read -p "이 백업을 복원하시겠습니까? (y/N): " CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
            exit 0
        fi
        
        print_step "Rclone 설정 복원 중..."
        docker run --rm -v $(pwd)/rclone-config:/config/rclone rclone/rclone sync gdrive:$RCLONE_ROOT/rclone-config /config/rclone -v
        chmod 600 rclone-config/rclone.conf 2>/dev/null || true
        print_success "Rclone 설정 파일 복원 완료"
        
        if [ -f "rclone-config/.vaultwarden-config" ]; then
            source rclone-config/.vaultwarden-config
            print_success "설정 정보 파일도 복원되었습니다."
            USE_SAVED_CONFIG=true
        fi
    else
        print_error "백업을 찾을 수 없습니다."
        exit 1
    fi
}

get_manual_config() {
    print_header "Vaultwarden 설정 입력"
    
    echo -e "${CYAN}컨테이너 이름 (기본: vaultwarden):${NC}"
    read -p "> " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-vaultwarden}
    BACKUP_CONTAINER_NAME="${CONTAINER_NAME}-backup"
    
    echo ""
    echo -e "${CYAN}도메인 (예: vault.example.com):${NC}"
    read -p "> " DOMAIN
    while [ -z "$DOMAIN" ]; do
        read -p "> " DOMAIN
    done
    DOMAIN_URL="https://$DOMAIN"
    
    echo ""
    echo -e "${CYAN}네트워크 이름 (기본: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    
    echo ""
    print_info "백업 주기 선택:"
    echo "  1) 1시간"
    echo "  2) 6시간"
    echo "  3) 12시간"
    echo "  4) 24시간"
    read -p "> " BACKUP_CHOICE
    case $BACKUP_CHOICE in
        1) BACKUP_INTERVAL=3600 ;;
        2) BACKUP_INTERVAL=21600 ;;
        3) BACKUP_INTERVAL=43200 ;;
        *) BACKUP_INTERVAL=86400 ;;
    esac
    print_success "설정 입력 완료"
}

get_admin_token() {
    print_header "Admin 토큰 설정"
    print_info "Admin 토큰을 설정하는 방법을 선택하세요:"
    echo "  1) 새 Admin 비밀번호로 토큰 생성"
    echo "  2) 기존 Admin 토큰 직접 입력"
    read -p "선택 (1/2): " TOKEN_CHOICE
    
    if [ "$TOKEN_CHOICE" = "2" ]; then
        echo -e "${CYAN}Admin 토큰을 입력하세요:${NC}"
        read -p "> " ADMIN_TOKEN
        echo "$ADMIN_TOKEN" > .admin-token
        chmod 600 .admin-token
    else
        while true; do
            read -sp "Admin 비밀번호: " ADMIN_PASSWORD
            echo ""
            read -sp "Admin 비밀번호 확인: " ADMIN_PASSWORD_CONFIRM
            echo ""
            if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
                break
            fi
            print_error "비밀번호가 일치하지 않습니다."
        done
        ADMIN_TOKEN=$(echo -n "$ADMIN_PASSWORD" | docker run --rm -i vaultwarden/server:latest /vaultwarden hash)
        echo "$ADMIN_TOKEN" > .admin-token
        chmod 600 .admin-token
    fi
    print_success "Admin 토큰이 설정되었습니다."
}

generate_docker_compose() {
    print_header "docker-compose.yml 생성"
    cat > docker-compose.yml << EOF
################################################################################
# Vaultwarden + Rclone 백업 (복구됨)
################################################################################

services:
  ${CONTAINER_NAME}:
    image: vaultwarden/server:latest
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    environment:
      - DOMAIN=${DOMAIN_URL}
      - SIGNUPS_ALLOWED=false
      - INVITATIONS_ALLOWED=true
      - SHOW_PASSWORD_HINT=false
      - WEB_VAULT_ENABLED=true
      - ADMIN_TOKEN=${ADMIN_TOKEN}
    volumes:
      - ./vaultwarden-data:/data
    networks:
      - ${NETWORK_NAME}

  ${BACKUP_CONTAINER_NAME}:
    image: rclone/rclone:latest
    container_name: ${BACKUP_CONTAINER_NAME}
    restart: unless-stopped
    environment:
      - TZ=Asia/Seoul
      - RCLONE_CONFIG=/config/rclone/rclone.conf
    volumes:
      - ./vaultwarden-data:/data:ro
      - ./rclone-config:/config/rclone
      - ./backup-logs:/logs
    command: >
      sh -c "
      while true; do
        YEAR=\\\$\\\$(date +%Y);
        LOGFILE=\"/logs/backup-\\\$\\\$YEAR.log\";
        echo \"[\\\$(date)] Starting encrypted backup...\" | tee -a \\\$\\\$LOGFILE;
        rclone sync /data gdrive-crypt:${RCLONE_ROOT}/vaultwarden-data --log-file=\\\$\\\$LOGFILE --log-level INFO;
        echo \"[\\\$(date)] Encrypted backup completed\" | tee -a \\\$\\\$LOGFILE;
        echo \"[\\\$(date)] Starting rclone-config backup...\" | tee -a \\\$\\\$LOGFILE;
        rclone sync /config/rclone gdrive:${RCLONE_ROOT}/rclone-config --log-file=\\\$\\\$LOGFILE --log-level INFO;
        echo \"[\\\$(date)] Rclone-config backup completed\" | tee -a \\\$\\\$LOGFILE;
        sleep ${BACKUP_INTERVAL};
      done
      "
    depends_on:
      - ${CONTAINER_NAME}
    networks:
      - ${NETWORK_NAME}

networks:
  ${NETWORK_NAME}:
    external: true
EOF
    print_success "docker-compose.yml 생성 완료"
}

restore_vaultwarden_data() {
    print_header "Vaultwarden 데이터 복원"
    print_warning "암호화된 백업을 복원합니다."
    
    print_step "암호화 리모트 확인 중..."
    REMOTES=$(docker run --rm -v $(pwd)/rclone-config:/config/rclone rclone/rclone listremotes)
    if ! echo "$REMOTES" | grep -q "gdrive-crypt:"; then
        print_error "gdrive-crypt 리모트를 찾을 수 없습니다."
        exit 1
    fi
    
    print_step "데이터 복원 중..."
    docker run --rm -v $(pwd)/rclone-config:/config/rclone -v $(pwd)/vaultwarden-data:/data rclone/rclone sync gdrive-crypt:$RCLONE_ROOT/vaultwarden-data /data -v
    print_success "Vaultwarden 데이터 복원 완료"
}

check_network() {
    print_header "Docker 네트워크 확인"
    if docker network ls | grep -q "\s${NETWORK_NAME}\s"; then
        print_success "$NETWORK_NAME 네트워크가 존재합니다."
    else
        read -p "$NETWORK_NAME 네트워크를 생성하시겠습니까? (y/N): " CREATE
        if [ "$CREATE" = "y" ] || [ "$CREATE" = "Y" ]; then
            docker network create --driver=bridge $NETWORK_NAME
            print_success "$NETWORK_NAME 네트워크가 생성되었습니다."
        fi
    fi
}

final_summary() {
    print_header "복원 완료!"
    echo ""
    print_success "Vaultwarden이 성공적으로 복원되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 서비스 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  도메인: $DOMAIN_URL"
    echo "  Admin: ${DOMAIN_URL}/admin"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 다음 단계"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. Nginx Proxy Manager 프록시 호스트 설정"
    echo "  2. docker compose up -d"
    echo "  3. 브라우저에서 접속 테스트"
    echo ""
    
    read -p "지금 서비스를 시작하시겠습니까? (y/N): " START
    if [ "$START" = "y" ] || [ "$START" = "Y" ]; then
        if docker compose up -d; then
            print_success "서비스가 시작되었습니다!"
        fi
    fi
}

main() {
    clear
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          Vaultwarden 재해 복구 스크립트                       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_docker
    check_working_directory
    create_directories
    setup_rclone_gdrive
    restore_rclone_config
    
    if [ "$USE_SAVED_CONFIG" != "true" ] || [ -z "$CONTAINER_NAME" ]; then
        get_manual_config
    fi
    
    get_admin_token
    generate_docker_compose
    restore_vaultwarden_data
    check_network
    final_summary
}

main
