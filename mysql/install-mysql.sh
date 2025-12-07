#!/bin/bash

################################################################################
# MySQL + phpMyAdmin 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기
# 3. Docker 네트워크 생성 (없는 경우)
# 4. docker-compose.yml 파일 자동 생성
# 5. MySQL + phpMyAdmin 서비스 시작
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/mysql/install-mysql.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/mysql/install-mysql.sh
#      chmod +x install-mysql.sh
#      sudo ./install-mysql.sh
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
# MySQL 버전에 따른 phpMyAdmin 권장 버전 반환
################################################################################
get_recommended_phpmyadmin_version() {
    local mysql_version=$1
    
    # MySQL 버전별 phpMyAdmin 호환성
    case $mysql_version in
        5.5|5.5.*)
            echo "4.9"  # MySQL 5.5는 phpMyAdmin 4.9까지 지원
            ;;
        5.6|5.6.*)
            echo "5.1"  # MySQL 5.6은 phpMyAdmin 5.1 권장
            ;;
        5.7|5.7.*)
            echo "5.2"  # MySQL 5.7은 phpMyAdmin 5.2 권장
            ;;
        8.0|8.0.*|8|8.*)
            echo "latest"  # MySQL 8.0+는 최신 phpMyAdmin 사용 가능
            ;;
        latest)
            echo "latest"  # latest MySQL은 latest phpMyAdmin
            ;;
        *)
            # 버전을 파싱하여 메이저 버전 확인
            local major_version=$(echo "$mysql_version" | cut -d'.' -f1)
            if [ "$major_version" -ge 8 ]; then
                echo "latest"
            elif [ "$major_version" -eq 5 ]; then
                echo "5.2"
            else
                echo "latest"
            fi
            ;;
    esac
}

################################################################################
# 사용자 입력 받기
################################################################################
get_user_input() {
    print_header "MySQL + phpMyAdmin 설정 정보 입력"
    
    # MySQL 컨테이너 이름
    echo -e "${CYAN}MySQL 컨테이너 이름을 입력하세요 (기본값: mysql):${NC}"
    read -p "> " MYSQL_CONTAINER
    MYSQL_CONTAINER=${MYSQL_CONTAINER:-mysql}
    print_success "MySQL 컨테이너 이름: $MYSQL_CONTAINER"
    
    # phpMyAdmin 컨테이너 이름
    echo ""
    echo -e "${CYAN}phpMyAdmin 컨테이너 이름을 입력하세요 (기본값: phpmyadmin):${NC}"
    read -p "> " PMA_CONTAINER
    PMA_CONTAINER=${PMA_CONTAINER:-phpmyadmin}
    print_success "phpMyAdmin 컨테이너 이름: $PMA_CONTAINER"
    
    # 네트워크 이름
    echo ""
    echo -e "${CYAN}Docker 네트워크 이름을 입력하세요 (기본값: main):${NC}"
    read -p "> " NETWORK_NAME
    NETWORK_NAME=${NETWORK_NAME:-main}
    print_success "네트워크 이름: $NETWORK_NAME"
    
    # MySQL 버전
    echo ""
    echo -e "${CYAN}MySQL 버전을 입력하세요 (기본값: latest):${NC}"
    print_info "예: 8.0, 8.4, 5.7, latest"
    read -p "> " MYSQL_VERSION
    MYSQL_VERSION=${MYSQL_VERSION:-latest}
    print_success "MySQL 버전: $MYSQL_VERSION"
    
    # phpMyAdmin 버전 (MySQL 버전에 따라 자동 추천)
    echo ""
    RECOMMENDED_PMA_VERSION=$(get_recommended_phpmyadmin_version "$MYSQL_VERSION")
    if [ "$RECOMMENDED_PMA_VERSION" != "latest" ]; then
        echo -e "${CYAN}phpMyAdmin 버전을 입력하세요 (기본값: ${RECOMMENDED_PMA_VERSION}, MySQL ${MYSQL_VERSION} 호환):${NC}"
        print_info "MySQL ${MYSQL_VERSION}에 권장되는 버전: ${RECOMMENDED_PMA_VERSION}"
    else
        echo -e "${CYAN}phpMyAdmin 버전을 입력하세요 (기본값: latest):${NC}"
    fi
    print_info "예: 5.2, 5.1, 4.9, latest"
    read -p "> " PMA_VERSION
    PMA_VERSION=${PMA_VERSION:-$RECOMMENDED_PMA_VERSION}
    print_success "phpMyAdmin 버전: $PMA_VERSION"
    
    # MySQL Root 비밀번호
    echo ""
    print_info "MySQL Root 비밀번호를 설정합니다."
    echo ""
    
    while true; do
        read -sp "MySQL Root 비밀번호: " MYSQL_ROOT_PASSWORD
        echo ""
        
        if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
            print_error "비밀번호를 입력해주세요."
            continue
        fi
        
        read -sp "MySQL Root 비밀번호 확인: " MYSQL_ROOT_PASSWORD_CONFIRM
        echo ""
        
        if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
            print_error "비밀번호가 일치하지 않습니다."
            continue
        fi
        
        break
    done
    
    print_success "MySQL Root 비밀번호 설정 완료"
    
    # MySQL 데이터베이스 이름
    echo ""
    echo -e "${CYAN}생성할 데이터베이스 이름을 입력하세요 (기본값: mydb):${NC}"
    read -p "> " MYSQL_DATABASE
    MYSQL_DATABASE=${MYSQL_DATABASE:-mydb}
    print_success "데이터베이스: $MYSQL_DATABASE"
    
    # MySQL 사용자 이름
    echo ""
    echo -e "${CYAN}MySQL 사용자 이름을 입력하세요 (기본값: myuser):${NC}"
    read -p "> " MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-myuser}
    print_success "MySQL 사용자: $MYSQL_USER"
    
    # MySQL 사용자 비밀번호
    echo ""
    print_info "MySQL 사용자 비밀번호를 설정합니다."
    echo ""
    
    while true; do
        read -sp "MySQL 사용자 비밀번호: " MYSQL_PASSWORD
        echo ""
        
        if [ -z "$MYSQL_PASSWORD" ]; then
            print_error "비밀번호를 입력해주세요."
            continue
        fi
        
        read -sp "MySQL 사용자 비밀번호 확인: " MYSQL_PASSWORD_CONFIRM
        echo ""
        
        if [ "$MYSQL_PASSWORD" != "$MYSQL_PASSWORD_CONFIRM" ]; then
            print_error "비밀번호가 일치하지 않습니다."
            continue
        fi
        
        break
    done
    
    print_success "MySQL 사용자 비밀번호 설정 완료"
    
    # MySQL 포트
    echo ""
    echo -e "${CYAN}MySQL 포트를 입력하세요 (기본값: 3306):${NC}"
    print_info "외부 접속을 허용하려면 포트를 지정하세요. 내부 접속만 사용하려면 엔터를 누르세요."
    read -p "> " MYSQL_PORT
    MYSQL_PORT=${MYSQL_PORT:-3306}
    print_success "MySQL 포트: $MYSQL_PORT"
    
    # phpMyAdmin 포트
    echo ""
    echo -e "${CYAN}phpMyAdmin 웹 포트를 입력하세요 (기본값: 8080):${NC}"
    read -p "> " PMA_PORT
    PMA_PORT=${PMA_PORT:-8080}
    
    # 포트 유효성 검사
    if ! [[ "$PMA_PORT" =~ ^[0-9]+$ ]] || [ "$PMA_PORT" -lt 1 ] || [ "$PMA_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    
    print_success "phpMyAdmin 포트: $PMA_PORT"
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "MySQL 컨테이너    : $MYSQL_CONTAINER"
    echo "phpMyAdmin 컨테이너: $PMA_CONTAINER"
    echo "네트워크 이름     : $NETWORK_NAME"
    echo "MySQL 버전        : $MYSQL_VERSION"
    echo "phpMyAdmin 버전   : $PMA_VERSION"
    echo "MySQL 포트        : $MYSQL_PORT"
    echo "phpMyAdmin 포트   : $PMA_PORT"
    echo "데이터베이스      : $MYSQL_DATABASE"
    echo "MySQL 사용자      : $MYSQL_USER"
    echo ""
    
    read -p "이 설정으로 진행하시겠습니까? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_warning "설정을 취소했습니다."
        exit 0
    fi
}

################################################################################
# Docker 네트워크 서브넷 정보 가져오기
################################################################################
get_network_subnet() {
    local network_name=$1
    
    # 네트워크의 서브넷 정보 가져오기
    NETWORK_SUBNET=$(docker network inspect $network_name -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
    
    if [ -z "$NETWORK_SUBNET" ]; then
        print_warning "네트워크 서브넷 정보를 가져올 수 없습니다."
        NETWORK_SUBNET="172.%.%.%"  # 기본값
    fi
    
    print_info "네트워크 서브넷: $NETWORK_SUBNET"
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
    
    # 네트워크 서브넷 정보 가져오기
    get_network_subnet $NETWORK_NAME
}

################################################################################
# 디렉토리 생성
################################################################################
create_directories() {
    print_header "디렉토리 구조 생성"
    
    # 필요한 디렉토리 생성
    mkdir -p mysql-data
    mkdir -p mysql-init
    
    print_success "디렉토리 생성 완료"
    echo "  - mysql-data/   (MySQL 데이터 저장)"
    echo "  - mysql-init/   (초기화 SQL 스크립트)"
}

################################################################################
# 초기화 SQL 스크립트 생성
################################################################################
generate_init_script() {
    print_header "초기화 스크립트 생성"
    
    # Root 계정 보안 설정 스크립트 (네트워크 서브넷 기반)
    cat > mysql-init/00-security.sql << EOF
-- Root 계정 보안 설정
-- 생성일: $(date)
-- Root 계정은 Docker 네트워크(${NETWORK_NAME}: ${NETWORK_SUBNET}) 내부에서만 접속 가능하도록 제한

-- 기존 외부 접속 Root 계정 모두 제거
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Docker 네트워크 서브넷에서만 Root 접속 허용
CREATE USER IF NOT EXISTS 'root'@'${NETWORK_SUBNET}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'${NETWORK_SUBNET}' WITH GRANT OPTION;

-- localhost Root 계정 유지
FLUSH PRIVILEGES;

-- 보안 설정 확인
SELECT User, Host FROM mysql.user WHERE User='root';
EOF
    
    print_success "Root 계정 보안 설정 스크립트 생성 완료"
    print_info "Root 계정은 네트워크 ${NETWORK_NAME}(${NETWORK_SUBNET})에서만 접속 가능합니다."
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
# MySQL + phpMyAdmin
################################################################################
# MySQL 데이터베이스 + phpMyAdmin 웹 관리 도구
#
# 접속 정보:
#   - phpMyAdmin: http://YOUR_SERVER_IP:${PMA_PORT}
#   - MySQL 호스트: ${MYSQL_CONTAINER}:3306
#   - 사용자: ${MYSQL_USER}
#   - 데이터베이스: ${MYSQL_DATABASE}
#
# 보안 설정:
#   - Root 계정: ${NETWORK_NAME} 네트워크(${NETWORK_SUBNET})에서만 접속 가능
#   - 일반 사용자(${MYSQL_USER}): 모든 위치에서 접속 가능
#
################################################################################

services:
  # MySQL 데이터베이스
  ${MYSQL_CONTAINER}:
    image: mysql:${MYSQL_VERSION}
    container_name: ${MYSQL_CONTAINER}
    restart: unless-stopped
    environment:
      # Root 비밀번호
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      
      # 데이터베이스 생성
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      
      # 사용자 생성
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      
      # 타임존 설정
      TZ: Asia/Seoul
      
    ports:
      - '${MYSQL_PORT}:3306'
      
    volumes:
      # MySQL 데이터 저장 경로
      - ./mysql-data:/var/lib/mysql
      
      # 초기화 SQL 스크립트 (보안 설정)
      - ./mysql-init:/docker-entrypoint-initdb.d
      
    networks:
      - ${NETWORK_NAME}
      
    command:
      # 문자셋 설정
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_general_ci
      # 인증 플러그인 설정 (구버전 호환)
      - --default-authentication-plugin=mysql_native_password

  # phpMyAdmin 웹 관리 도구
  ${PMA_CONTAINER}:
    image: phpmyadmin:${PMA_VERSION}
    container_name: ${PMA_CONTAINER}
    restart: unless-stopped
    environment:
      # MySQL 호스트 설정
      PMA_HOST: ${MYSQL_CONTAINER}
      
      # Root 로그인 허용 (네트워크 내부에서만 가능)
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      
      # 업로드 제한 설정
      UPLOAD_LIMIT: 100M
      
      # 타임존 설정
      TZ: Asia/Seoul
      
    ports:
      - '${PMA_PORT}:80'
      
    networks:
      - ${NETWORK_NAME}
      
    depends_on:
      - ${MYSQL_CONTAINER}

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
    cat > .mysql-config << EOF
# MySQL + phpMyAdmin 설정 정보
# 생성일: $(date)

# 컨테이너 정보
MYSQL_CONTAINER=$MYSQL_CONTAINER
PMA_CONTAINER=$PMA_CONTAINER
NETWORK_NAME=$NETWORK_NAME
NETWORK_SUBNET=$NETWORK_SUBNET

# 버전 정보
MYSQL_VERSION=$MYSQL_VERSION
PMA_VERSION=$PMA_VERSION

# 포트 정보
MYSQL_PORT=$MYSQL_PORT
PMA_PORT=$PMA_PORT

# 데이터베이스 정보
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER

# 보안 정보
# - Root 접속: ${NETWORK_NAME} 네트워크(${NETWORK_SUBNET})에서만 가능
# - 일반 사용자(${MYSQL_USER}): 모든 위치에서 접속 가능

# phpMyAdmin 접속: http://YOUR_SERVER_IP:${PMA_PORT}
# MySQL 직접 접속: mysql -h localhost -P ${MYSQL_PORT} -u ${MYSQL_USER} -p
EOF
    
    chmod 600 .mysql-config
    
    print_success "설정 정보가 .mysql-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "MySQL + phpMyAdmin을 시작합니다..."
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
    print_info "MySQL이 초기화되는 중입니다... (30초 대기)"
    sleep 30
    
    # 컨테이너 상태 확인
    if docker ps | grep -q $MYSQL_CONTAINER && docker ps | grep -q $PMA_CONTAINER; then
        print_success "모든 컨테이너가 정상적으로 실행 중입니다."
    else
        print_warning "일부 컨테이너 상태를 확인할 수 없습니다."
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
    print_success "MySQL + phpMyAdmin 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ docker-compose.yml    (Docker Compose 설정)"
    echo "  ✓ .mysql-config         (설정 정보 - 안전하게 보관!)"
    echo "  ✓ mysql-data/           (MySQL 데이터 저장소)"
    echo "  ✓ mysql-init/           (초기화 SQL 스크립트)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  MySQL 컨테이너    : $MYSQL_CONTAINER"
    echo "  phpMyAdmin 컨테이너: $PMA_CONTAINER"
    echo "  네트워크          : $NETWORK_NAME"
    echo "  네트워크 서브넷    : $NETWORK_SUBNET"
    echo "  MySQL 버전        : $MYSQL_VERSION"
    echo "  phpMyAdmin 버전   : $PMA_VERSION"
    echo "  MySQL 포트        : $MYSQL_PORT"
    echo "  phpMyAdmin 포트   : $PMA_PORT"
    echo "  데이터베이스      : $MYSQL_DATABASE"
    echo "  MySQL 사용자      : $MYSQL_USER"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 접속 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  phpMyAdmin: http://${SERVER_IP}:${PMA_PORT}"
    echo ""
    echo "  로그인 정보 (Root - 네트워크 내부 전용):"
    echo "    사용자: root"
    echo "    비밀번호: (설정한 Root 비밀번호)"
    echo "    접속 제한: ${NETWORK_NAME} 네트워크(${NETWORK_SUBNET})만 가능"
    echo ""
    echo "  로그인 정보 (일반 사용자 - 외부 접속 가능):"
    echo "    사용자: $MYSQL_USER"
    echo "    비밀번호: (설정한 사용자 비밀번호)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔌 MySQL 직접 접속"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  # 호스트에서 일반 사용자로 접속 (외부 접속 가능)"
    echo "  mysql -h localhost -P ${MYSQL_PORT} -u ${MYSQL_USER} -p"
    echo ""
    echo "  # 같은 네트워크 컨테이너에서 Root 접속 (내부 전용)"
    echo "  docker exec -it ${MYSQL_CONTAINER} mysql -u root -p"
    echo ""
    echo "  # 다른 컨테이너에서 Root 접속 (${NETWORK_NAME} 네트워크 내부)"
    echo "  mysql -h ${MYSQL_CONTAINER} -u root -p"
    echo ""
    echo "  # 다른 컨테이너에서 일반 사용자 접속"
    echo "  mysql -h ${MYSQL_CONTAINER} -u ${MYSQL_USER} -p"
    echo ""
    echo "  # 연결 문자열 (애플리케이션)"
    echo "  Host: ${MYSQL_CONTAINER}"
    echo "  Port: 3306"
    echo "  Database: ${MYSQL_DATABASE}"
    echo "  User: ${MYSQL_USER} (일반 작업) 또는 root (관리 작업, 네트워크 내부만)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔒 보안 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Root 계정: ${NETWORK_NAME} 네트워크(${NETWORK_SUBNET})에서만 접속 가능"
    echo "  ✓ 외부에서는 일반 사용자(${MYSQL_USER})로만 접속 가능"
    echo "  ✓ Root 접속이 필요한 경우:"
    echo "    - docker exec 사용 (로컬)"
    echo "    - ${NETWORK_NAME} 네트워크 내부 컨테이너에서만 가능"
    echo "  ✓ phpMyAdmin은 ${NETWORK_NAME} 네트워크 내부에서 실행되므로 Root 접속 가능"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • MySQL 로그: docker compose logs -f ${MYSQL_CONTAINER}"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • MySQL 쉘 접속: docker exec -it ${MYSQL_CONTAINER} mysql -u root -p"
    echo "  • Root 계정 확인: docker exec -it ${MYSQL_CONTAINER} mysql -u root -p -e \"SELECT User, Host FROM mysql.user WHERE User='root';\""
    echo "  • 백업: docker exec ${MYSQL_CONTAINER} mysqldump -u root -p --all-databases > backup.sql"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 다음 보안 작업을 수행하세요:"
    echo "    1. 방화벽 설정 (MySQL 포트 외부 접근 제한 권장)"
    echo "    2. phpMyAdmin 관리자 IP만 접근 허용"
    echo "    3. 정기적인 데이터베이스 백업"
    echo "    4. Root 계정은 ${NETWORK_NAME} 네트워크(${NETWORK_SUBNET})에서만 접속 가능"
    echo "    5. 외부에서 관리 작업이 필요한 경우 일반 사용자에게 필요한 권한만 부여"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • MySQL 공식 문서: https://dev.mysql.com/doc/"
    echo "  • phpMyAdmin 문서: https://docs.phpmyadmin.net/"
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
    echo "║       MySQL + phpMyAdmin 자동 설치 스크립트                    ║"
    echo "║       데이터베이스 + 웹 관리 도구                              ║"
    echo "║       Root 접속: 네트워크 서브넷 기반 보안 적용                ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker                # 1. Docker 확인
    get_user_input              # 2. 사용자 입력
    check_and_create_network    # 3. 네트워크 확인 및 생성 + 서브넷 정보 가져오기
    create_directories          # 4. 디렉토리 생성
    generate_init_script        # 5. 초기화 스크립트 생성 (네트워크 기반 보안)
    generate_docker_compose     # 6. docker-compose.yml 생성
    save_configuration          # 7. 설정 정보 저장
    start_service               # 8. 서비스 시작
    final_summary               # 9. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
