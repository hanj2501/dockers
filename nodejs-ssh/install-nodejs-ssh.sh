#!/bin/bash

################################################################################
# Node.js + SSH 자동 설치 스크립트
################################################################################
# 이 스크립트는 다음을 자동으로 수행합니다:
# 1. Docker 및 Docker Compose 설치 확인
# 2. 사용자로부터 설정 정보 입력 받기 (Node.js 버전 선택 포함)
# 3. Docker 네트워크 생성 (없는 경우)
# 4. Dockerfile 자동 생성 (Ubuntu + Node.js + SSH)
# 5. Docker 이미지 빌드
# 6. docker-compose.yml 파일 자동 생성
# 7. Node.js + SSH 서비스 시작
#
# 지원 Node.js 버전:
# - Node.js 22 (Current, 기본값)
# - Node.js 20 (LTS)
# - Node.js 18 (LTS)
# - 사용자 지정 버전
#
# 사용 방법:
#   1. 원라인 설치:
#      curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/nodejs-ssh/install-nodejs-ssh.sh | sudo bash
#
#   2. 또는 단계별 실행:
#      wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/nodejs-ssh/install-nodejs-ssh.sh
#      chmod +x install-nodejs-ssh.sh
#      sudo ./install-nodejs-ssh.sh
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
    print_header "Node.js + SSH 설정 정보 입력"
    
    # 컨테이너 이름
    echo -e "${CYAN}Docker 컨테이너 이름을 입력하세요 (기본값: nodejs-ssh):${NC}"
    read -p "> " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-nodejs-ssh}
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
    
    # Node.js 애플리케이션 외부 포트
    echo ""
    echo -e "${CYAN}Node.js 애플리케이션 외부 포트를 입력하세요 (호스트에서 접근할 포트, 기본값: 3000):${NC}"
    read -p "> " APP_EXTERNAL_PORT
    APP_EXTERNAL_PORT=${APP_EXTERNAL_PORT:-3000}
    
    # 포트 유효성 검사
    if ! [[ "$APP_EXTERNAL_PORT" =~ ^[0-9]+$ ]] || [ "$APP_EXTERNAL_PORT" -lt 1 ] || [ "$APP_EXTERNAL_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    print_success "외부 포트: $APP_EXTERNAL_PORT"
    
    # Node.js 애플리케이션 내부 포트
    echo ""
    echo -e "${CYAN}Node.js 애플리케이션 내부 포트를 입력하세요 (컨테이너 내부 포트, 기본값: 3000):${NC}"
    read -p "> " APP_INTERNAL_PORT
    APP_INTERNAL_PORT=${APP_INTERNAL_PORT:-3000}
    
    # 포트 유효성 검사
    if ! [[ "$APP_INTERNAL_PORT" =~ ^[0-9]+$ ]] || [ "$APP_INTERNAL_PORT" -lt 1 ] || [ "$APP_INTERNAL_PORT" -gt 65535 ]; then
        print_error "유효하지 않은 포트 번호입니다. (1-65535)"
        exit 1
    fi
    print_success "내부 포트: $APP_INTERNAL_PORT"
    
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
    
    # Node.js 버전 선택
    echo ""
    echo -e "${CYAN}Node.js 버전을 선택하세요:${NC}"
    echo "  1) Node.js 22 (Current, 기본값)"
    echo "  2) Node.js 20 (LTS)"
    echo "  3) Node.js 18 (LTS)"
    echo "  4) 직접 입력"
    read -p "> " NODE_VERSION_CHOICE
    NODE_VERSION_CHOICE=${NODE_VERSION_CHOICE:-1}
    
    case $NODE_VERSION_CHOICE in
        1)
            NODE_VERSION="22"
            NODE_VERSION_NAME="22 (Current)"
            ;;
        2)
            NODE_VERSION="20"
            NODE_VERSION_NAME="20 (LTS)"
            ;;
        3)
            NODE_VERSION="18"
            NODE_VERSION_NAME="18 (LTS)"
            ;;
        4)
            echo -e "${CYAN}Node.js 버전을 입력하세요 (예: 22, 20, 18):${NC}"
            read -p "> " NODE_VERSION
            if ! [[ "$NODE_VERSION" =~ ^[0-9]+$ ]]; then
                print_error "유효하지 않은 버전입니다. 기본값(22)을 사용합니다."
                NODE_VERSION="22"
                NODE_VERSION_NAME="22 (Current)"
            else
                NODE_VERSION_NAME="$NODE_VERSION"
            fi
            ;;
        *)
            print_warning "잘못된 선택입니다. 기본값(22)을 사용합니다."
            NODE_VERSION="22"
            NODE_VERSION_NAME="22 (Current)"
            ;;
    esac
    print_success "Node.js 버전: $NODE_VERSION_NAME"
    
    # 타임존 설정
    echo ""
    echo -e "${CYAN}서버 타임존을 입력하세요 (기본값: Asia/Seoul):${NC}"
    read -p "> " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Seoul}
    print_success "타임존: $TIMEZONE"
    
    # 설정 확인
    echo ""
    print_header "입력한 설정 확인"
    echo "컨테이너 이름       : $CONTAINER_NAME"
    echo "네트워크 이름       : $NETWORK_NAME"
    echo "SSH 포트           : $SSH_PORT"
    echo "앱 외부 포트       : $APP_EXTERNAL_PORT (호스트)"
    echo "앱 내부 포트       : $APP_INTERNAL_PORT (컨테이너)"
    echo "포트 매핑          : $APP_EXTERNAL_PORT:$APP_INTERNAL_PORT"
    echo "SSH 사용자         : $SSH_USER"
    echo "Node.js 버전       : $NODE_VERSION_NAME"
    echo "타임존             : $TIMEZONE"
    echo "작업 디렉토리       : app/"
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
    
    # 애플리케이션 디렉토리 생성
    mkdir -p app
    
    # 기본 package.json 생성
    if [ ! -f app/package.json ]; then
        cat > ./app/package.json << 'EOF'
{
  "name": "nodejs-app",
  "version": "1.0.0",
  "description": "Node.js application with SSH access",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "start:service": "node index.js",
    "dev": "node index.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
    fi
    
    # 기본 index.js 생성
    if [ ! -f app/index.js ]; then
        cat > ./app/index.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Node.js Server</title>
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
        .info {
            margin-top: 30px;
            background: rgba(255, 255, 255, 0.1);
            padding: 20px;
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Node.js ${process.version} Server</h1>
        <p>서버가 정상적으로 실행 중입니다!</p>
        <div class="info">
            <p><strong>Environment:</strong> ${process.env.NODE_ENV || 'development'}</p>
            <p><strong>Internal Port:</strong> ${PORT}</p>
        </div>
    </div>
</body>
</html>
  `);
});

app.get('/api/status', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    nodeVersion: process.version,
    uptime: process.uptime(),
    port: PORT
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Node.js version: ${process.version}`);
});
EOF
    fi
    
    # README 파일 생성
    if [ ! -f app/README.md ]; then
        cat > ./app/README.md << 'EOF'
# Node.js 애플리케이션 디렉토리

이 디렉토리는 Node.js 애플리케이션 코드를 저장하는 곳입니다.

## 디렉토리 구조
```
app/
├── index.js           # 메인 애플리케이션 파일
├── package.json       # 프로젝트 의존성 정의
└── README.md         # 이 파일
```

## 사용 방법

### 1. 애플리케이션 수정

SSH로 접속하여 코드를 수정하세요:
```bash
ssh user@server -p 2222
cd ~/app
nano index.js
```

### 2. 패키지 설치

새로운 npm 패키지를 설치하려면:
```bash
cd ~/app
pnpm install package-name

# 또는 npm 사용
npm install package-name
```

### 3. 애플리케이션 재시작

코드를 수정한 후 컨테이너를 재시작:
```bash
docker compose restart
```

또는 컨테이너 내부에서:
```bash
docker exec nodejs-ssh pm2 restart all
```

## 개발 팁

### 파일 업로드 (SCP)
```bash
# 단일 파일
scp -P 2222 myfile.js user@server:~/app/

# 디렉토리 전체
scp -P 2222 -r ./src user@server:~/app/
```

### 로그 확인
```bash
# Docker 로그
docker compose logs -f

# 컨테이너 내부 로그
docker exec nodejs-ssh pm2 logs
```

### Node.js 버전 확인
```bash
docker exec nodejs-ssh node --version
```

### npm 패키지 관리
```bash
# pnpm으로 패키지 설치 (권장)
docker exec nodejs-ssh pnpm install

# npm으로 패키지 설치
docker exec nodejs-ssh npm install

# 개발 의존성 설치
docker exec nodejs-ssh pnpm install --save-dev package-name

# 패키지 업데이트
docker exec nodejs-ssh pnpm update
```

## 프로덕션 배포

프로덕션 환경에서는:
1. 환경 변수를 docker-compose.yml에서 설정
2. PM2를 사용한 프로세스 관리 (이미 포함됨)
3. 로그 로테이션 설정
4. 보안 강화 (방화벽, SSH 키 인증 등)

## 문제 해결

### 포트 충돌
다른 포트로 변경하려면 docker-compose.yml 수정:
```yaml
ports:
  - '3001:3000'  # 호스트:컨테이너
```

### 패키지 설치 오류
package-lock.json과 node_modules 삭제 후 재설치:
```bash
# pnpm 사용 시
rm -rf pnpm-lock.yaml node_modules
pnpm install

# npm 사용 시
rm -rf package-lock.json node_modules
npm install
```
EOF
    fi
    
    # 현재 로그인된 사용자 확인
    REAL_USER=${SUDO_USER:-$USER}
    
    # 소유자를 실제 사용자로 변경
    chown -R $REAL_USER:$REAL_USER app
    
    print_success "디렉토리 생성 완료"
    echo "  - ~/app/ (Node.js 애플리케이션 디렉토리, 소유자: $REAL_USER)"
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
    cat > Dockerfile << EOF
FROM ubuntu:22.04

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
ENV NODE_VERSION=${NODE_VERSION}

# 기본 패키지 업데이트 및 설치
RUN apt-get update && apt-get install -y \\
    curl \\
    wget \\
    git \\
    openssh-server \\
    sudo \\
    tzdata \\
    ca-certificates \\
    gnupg \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Node.js 설치
RUN mkdir -p /etc/apt/keyrings && \\
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \\
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_\${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \\
    apt-get update && \\
    apt-get install -y nodejs && \\
    apt-get clean && \\
    rm -rf /var/lib/apt/lists/*

# npm 최신 버전으로 업데이트 및 pnpm, PM2 설치
RUN npm install -g npm@latest pnpm pm2

# SSH 디렉토리 생성
RUN mkdir /var/run/sshd

# SSH 설정
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \\
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \\
    && echo "AllowUsers *" >> /etc/ssh/sshd_config

# 작업 디렉토리 생성
RUN mkdir -p /app

# 작업 디렉토리 설정
WORKDIR /app

# 시작 스크립트 복사
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 포트 노출
EXPOSE ${APP_INTERNAL_PORT} 22

# 엔트리포인트 설정
ENTRYPOINT ["/entrypoint.sh"]
EOF
    
    print_success "Dockerfile 생성 완료"
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
        
        # 사용자 홈 디렉토리에 app 링크 생성
        ln -sf /app /home/$SSH_USER/app
        
        echo "SSH 사용자 '$SSH_USER' 생성 완료"
    fi
fi

# SSH 호스트 키 생성
ssh-keygen -A

# SSH 서비스 시작
/usr/sbin/sshd

# package.json이 존재하면 의존성 설치
if [ -f /app/package.json ]; then
    echo "Installing Node.js dependencies with pnpm..."
    cd /app
    pnpm install
fi

# Node.js 애플리케이션 시작 (PM2 사용)
if [ -f /app/index.js ]; then
    echo "Starting Node.js application with PM2..."
    cd /app
    pm2 start "pnpm start:service" --name "app" --no-daemon
else
    echo "No index.js found. Starting SSH only mode..."
    # SSH만 유지
    tail -f /dev/null
fi
ENTRYPOINT_EOF
    
    chmod +x entrypoint.sh
    print_success "엔트리포인트 스크립트 생성 완료"
}

################################################################################
# Docker 이미지 빌드
################################################################################
build_docker_image() {
    print_header "Docker 이미지 빌드"
    
    IMAGE_NAME="nodejs-ssh-custom"
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
# Node.js + SSH Server
################################################################################
# Node.js 애플리케이션 서버와 SSH 접속이 가능한 환경
#
# 접속 정보:
# - HTTP: http://YOUR_SERVER_IP:${APP_EXTERNAL_PORT}
# - SSH: ssh ${SSH_USER}@YOUR_SERVER_IP -p ${SSH_PORT}
# - 애플리케이션 경로: ~/app
#
# 포트 매핑:
# - 외부 포트 (호스트): ${APP_EXTERNAL_PORT}
# - 내부 포트 (컨테이너): ${APP_INTERNAL_PORT}
#
################################################################################

services:
  # Node.js + SSH 서버
  ${CONTAINER_NAME}:
    image: nodejs-ssh-custom:latest
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    environment:
      # 타임존 설정
      - TZ=${TIMEZONE}
      # SSH 사용자 설정
      - SSH_USER=${SSH_USER}
      - SSH_PASSWORD=${SSH_PASSWORD}
      # Node.js 환경 변수
      - NODE_ENV=production
      - PORT=${APP_INTERNAL_PORT}
    ports:
      # Node.js 애플리케이션 포트 (외부:내부)
      - '${APP_EXTERNAL_PORT}:${APP_INTERNAL_PORT}'
      # SSH 포트
      - '${SSH_PORT}:22'
    volumes:
      # 애플리케이션 디렉토리
      - ./app:/app
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
    cat > .nodejs-ssh-config << EOF
# Node.js + SSH 설정 정보
# 생성일: $(date)

# 컨테이너 정보
CONTAINER_NAME=$CONTAINER_NAME
NETWORK_NAME=$NETWORK_NAME

# 포트 정보
SSH_PORT=$SSH_PORT
APP_EXTERNAL_PORT=$APP_EXTERNAL_PORT
APP_INTERNAL_PORT=$APP_INTERNAL_PORT

# SSH 사용자 정보
SSH_USER=$SSH_USER

# 타임존
TIMEZONE=$TIMEZONE

# 경로 정보
APP_PATH=./app

# Docker 이미지
IMAGE_NAME=nodejs-ssh-custom:latest

# Node.js 버전
NODE_VERSION=$NODE_VERSION

# 접속 정보:
# HTTP: http://YOUR_SERVER_IP:${APP_EXTERNAL_PORT}
# SSH: ssh ${SSH_USER}@YOUR_SERVER_IP -p ${SSH_PORT}

# 포트 매핑:
# - 외부 포트 (호스트): ${APP_EXTERNAL_PORT}
# - 내부 포트 (컨테이너): ${APP_INTERNAL_PORT}

# 애플리케이션 관리:
# - 코드 수정 후 재시작: docker compose restart
# - PM2 상태 확인: docker exec ${CONTAINER_NAME} pm2 status
# - PM2 로그 확인: docker exec ${CONTAINER_NAME} pm2 logs
EOF
    
    chmod 600 .nodejs-ssh-config
    print_success "설정 정보가 .nodejs-ssh-config 파일에 저장되었습니다."
}

################################################################################
# 서비스 시작
################################################################################
start_service() {
    print_header "서비스 시작"
    
    print_info "Node.js + SSH 서버를 시작합니다..."
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
    print_info "컨테이너가 초기화되는 중입니다... (15초 대기)"
    sleep 15
    
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
    print_success "Node.js + SSH 서버 설치가 완료되었습니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 생성된 파일 및 디렉토리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Dockerfile (Docker 이미지 빌드 파일)"
    echo "  ✓ entrypoint.sh (시작 스크립트)"
    echo "  ✓ docker-compose.yml (Docker Compose 설정)"
    echo "  ✓ .nodejs-ssh-config (설정 정보)"
    echo "  ✓ app/ (Node.js 애플리케이션 디렉토리)"
    echo "  ✓ app/package.json (npm 패키지 설정)"
    echo "  ✓ app/index.js (메인 애플리케이션 파일)"
    echo "  ✓ app/README.md (애플리케이션 가이드)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 설정 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  컨테이너 이름       : $CONTAINER_NAME"
    echo "  네트워크           : $NETWORK_NAME"
    echo "  SSH 포트           : $SSH_PORT"
    echo "  앱 외부 포트       : $APP_EXTERNAL_PORT (호스트)"
    echo "  앱 내부 포트       : $APP_INTERNAL_PORT (컨테이너)"
    echo "  포트 매핑          : $APP_EXTERNAL_PORT:$APP_INTERNAL_PORT"
    echo "  SSH 사용자         : $SSH_USER"
    echo "  타임존             : $TIMEZONE"
    echo "  Node.js 버전       : $NODE_VERSION_NAME"
    echo "  패키지 매니저       : pnpm (npm도 사용 가능)"
    echo "  작업 디렉토리       : app/"
    echo "  이미지             : nodejs-ssh-custom:latest"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 접속 정보"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📌 HTTP 접속:"
    echo "     http://${SERVER_IP}:${APP_EXTERNAL_PORT}"
    echo ""
    echo "  📌 API 상태 확인:"
    echo "     http://${SERVER_IP}:${APP_EXTERNAL_PORT}/api/status"
    echo ""
    echo "  📌 포트 매핑:"
    echo "     외부 포트 (호스트): ${APP_EXTERNAL_PORT}"
    echo "     내부 포트 (컨테이너): ${APP_INTERNAL_PORT}"
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
    echo "  # 접속 후 디렉토리 확인"
    echo "  cd ~/app              # Node.js 애플리케이션 디렉토리"
    echo ""
    echo "  # 파일 업로드 (SCP 사용)"
    echo "  scp -P ${SSH_PORT} app.js ${SSH_USER}@${SERVER_IP}:~/app/"
    echo "  scp -P ${SSH_PORT} -r src/ ${SSH_USER}@${SERVER_IP}:~/app/"
    echo ""
    echo "  # Node.js 버전 확인"
    echo "  docker exec ${CONTAINER_NAME} node --version"
    echo ""
    echo "  # pnpm 버전 확인"
    echo "  docker exec ${CONTAINER_NAME} pnpm --version"
    echo ""
    echo "  # pnpm으로 패키지 설치"
    echo "  docker exec ${CONTAINER_NAME} pnpm install package-name"
    echo ""
    echo "  # npm으로 패키지 설치"
    echo "  docker exec ${CONTAINER_NAME} npm install package-name"
    echo ""
    echo "  # PM2 상태 확인"
    echo "  docker exec ${CONTAINER_NAME} pm2 status"
    echo ""
    echo "  # PM2 로그 확인"
    echo "  docker exec ${CONTAINER_NAME} pm2 logs"
    echo ""
    echo "  # 애플리케이션 재시작"
    echo "  docker compose restart"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️ 개발 가이드"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. 코드 수정:"
    echo "     - SSH로 접속하여 직접 수정"
    echo "     - 또는 SCP로 파일 업로드"
    echo ""
    echo "  2. 패키지 추가 (pnpm 권장):"
    echo "     docker exec ${CONTAINER_NAME} pnpm install express"
    echo ""
    echo "  3. 개발 의존성 추가:"
    echo "     docker exec ${CONTAINER_NAME} pnpm install --save-dev nodemon"
    echo ""
    echo "  4. 애플리케이션 재시작:"
    echo "     docker compose restart"
    echo ""
    echo "  5. 실시간 로그 확인:"
    echo "     docker compose logs -f"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 유용한 명령어"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • 로그 확인: docker compose logs -f"
    echo "  • 서비스 재시작: docker compose restart"
    echo "  • 서비스 중지: docker compose down"
    echo "  • 컨테이너 상태: docker compose ps"
    echo "  • 컨테이너 접속: docker exec -it ${CONTAINER_NAME} bash"
    echo "  • Node.js REPL: docker exec -it ${CONTAINER_NAME} node"
    echo "  • PM2 모니터링: docker exec -it ${CONTAINER_NAME} pm2 monit"
    echo "  • 이미지 재빌드: docker build -t nodejs-ssh-custom:latest ."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️ 보안 주의사항"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔴 다음 보안 작업을 수행하세요:"
    echo "  1. 강력한 SSH 비밀번호 사용"
    echo "  2. 방화벽 설정 (신뢰할 수 있는 IP만 SSH 접근 허용)"
    echo "  3. SSH 키 인증 사용 권장"
    echo "  4. 정기적인 비밀번호 변경"
    echo "  5. 환경 변수로 민감 정보 관리 (.env 파일 사용)"
    echo "  6. 디스크 공간 모니터링 (node_modules 크기 주의)"
    echo "  7. 정기적인 pnpm/npm 패키지 업데이트"
    echo "  8. 프로덕션에서는 NODE_ENV=production 설정"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 참고 문서"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • Node.js 문서: https://nodejs.org/docs/latest/api/"
    echo "  • pnpm 문서: https://pnpm.io/"
    echo "  • Express.js 문서: https://expressjs.com/"
    echo "  • PM2 문서: https://pm2.keymetrics.io/docs/"
    echo "  • Docker 문서: https://docs.docker.com/"
    echo "  • 애플리케이션 가이드: app/README.md"
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
    echo "║         Node.js + SSH 자동 설치 스크립트                      ║"
    echo "║         Node.js Server with SSH Access                        ║"
    echo "║         (v18 LTS / v20 LTS / v22 Current)                     ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 실행 단계
    check_docker              # 1. Docker 확인
    get_user_input           # 2. 사용자 입력
    check_and_create_network # 3. 네트워크 확인 및 생성
    create_directories       # 4. 디렉토리 생성
    generate_dockerfile      # 5. Dockerfile 생성
    generate_entrypoint      # 6. 엔트리포인트 스크립트 생성
    build_docker_image       # 7. Docker 이미지 빌드
    generate_docker_compose  # 8. docker-compose.yml 생성
    save_configuration       # 9. 설정 정보 저장
    start_service           # 10. 서비스 시작
    final_summary           # 11. 최종 요약
}

################################################################################
# 스크립트 실행
################################################################################
main
