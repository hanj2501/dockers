# Nginx + SSH 자동 설치 스크립트

Docker를 사용하여 Nginx 웹 서버와 SSH 접속 환경을 자동으로 구성하는 스크립트입니다.

## 📋 목차

- [특징](#특징)
- [요구사항](#요구사항)
- [빠른 시작](#빠른-시작)
- [설정 항목](#설정-항목)
- [사용 방법](#사용-방법)
- [파일 구조](#파일-구조)
- [접속 방법](#접속-방법)
- [유용한 명령어](#유용한-명령어)
- [보안 권장사항](#보안-권장사항)
- [문제 해결](#문제-해결)

## ✨ 특징

- 🚀 **원클릭 설치**: 하나의 스크립트로 모든 설정 자동화
- 🔧 **커스텀 빌드**: Dockerfile을 통한 완전한 커스터마이징
- 🌐 **Nginx 웹 서버**: Ubuntu 22.04 + Nginx 최신 버전
- 🔐 **SSH 접속**: OpenSSH Server 내장
- 📦 **Docker Compose**: 간편한 컨테이너 관리
- 🎨 **사용자 친화적**: 대화형 설정 인터페이스
- 📁 **자동 디렉토리 구성**: ~/html 웹 루트 자동 생성

## 📦 요구사항

### 필수 요구사항
- Docker (20.10 이상)
- Docker Compose (v2.0 이상)
- Linux 운영체제 (Ubuntu, Debian, CentOS 등)
- Root 권한 또는 sudo 권한

### 설치 확인
```bash
# Docker 버전 확인
docker --version

# Docker Compose 버전 확인
docker compose version
```

### Docker 설치 (미설치 시)
```bash
curl -fsSL https://get.docker.com | sudo bash
```

## 🚀 빠른 시작

### 1. 스크립트 다운로드
```bash
# Git으로 다운로드
git clone <repository-url>
cd nginx-ssh-installer

# 또는 직접 다운로드
wget https://raw.githubusercontent.com/hanj2501/dockers/main/nginx-ssh/install-nginx-ssh.sh
chmod +x install-nginx-ssh.sh
```

### 2. 스크립트 실행
```bash
sudo ./install-nginx-ssh.sh
```

### 3. 설정 입력
스크립트가 대화형으로 다음 정보를 요청합니다:

- Docker 컨테이너 이름 (기본값: nginx-ssh)
- Docker 네트워크 이름 (기본값: main)
- SSH 포트 (기본값: 2222)
- HTTP 포트 (기본값: 80)
- SSH 사용자 이름 (기본값: admin)
- SSH 비밀번호
- 서버 타임존 (기본값: Asia/Seoul)

### 4. 자동 설치 진행
스크립트가 자동으로:
- Dockerfile 생성
- Nginx 설정 파일 생성
- Docker 이미지 빌드
- docker-compose.yml 생성
- 컨테이너 시작

## ⚙️ 설정 항목

| 항목 | 기본값 | 설명 |
|------|--------|------|
| 컨테이너 이름 | nginx-ssh | Docker 컨테이너 이름 |
| 네트워크 이름 | main | Docker 네트워크 이름 |
| SSH 포트 | 2222 | SSH 접속 포트 (1-65535) |
| HTTP 포트 | 80 | 웹 서버 포트 (1-65535) |
| SSH 사용자 | admin | SSH 로그인 사용자명 |
| SSH 비밀번호 | (직접 입력) | SSH 로그인 비밀번호 |
| 타임존 | Asia/Seoul | 서버 타임존 설정 |
| HTML 경로 | ~/html | 웹 루트 디렉토리 |

## 📖 사용 방법

### HTTP 접속
웹 브라우저에서 다음 주소로 접속:
```
http://YOUR_SERVER_IP:포트번호
```

### SSH 접속
```bash
ssh 사용자명@YOUR_SERVER_IP -p SSH포트

# 예시
ssh admin@192.168.1.100 -p 2222
```

### 파일 업로드 (SCP)
```bash
# 단일 파일 업로드
scp -P 2222 index.html admin@YOUR_SERVER_IP:~/html/

# 디렉토리 전체 업로드
scp -P 2222 -r ./website/* admin@YOUR_SERVER_IP:~/html/
```

### 파일 업로드 (SFTP)
```bash
# SFTP 접속
sftp -P 2222 admin@YOUR_SERVER_IP

# SFTP 명령어
put index.html html/          # 파일 업로드
put -r ./website html/        # 디렉토리 업로드
ls html/                      # 파일 목록 확인
exit                          # 종료
```

### SSH 접속 후 파일 편집
```bash
# SSH 접속
ssh admin@YOUR_SERVER_IP -p 2222

# html 디렉토리로 이동
cd ~/html

# 파일 편집
nano index.html

# 또는 vim 사용
vim index.html
```

## 📁 파일 구조

설치 후 생성되는 파일 구조:

```
nginx-ssh-installer/
├── Dockerfile                    # Docker 이미지 빌드 파일
├── default.conf                  # Nginx 설정 파일
├── entrypoint.sh                 # 컨테이너 시작 스크립트
├── docker-compose.yml            # Docker Compose 설정
├── .nginx-ssh-config             # 설정 정보 저장
├── install-nginx-ssh.sh          # 설치 스크립트
└── README.md                     # 이 문서

~/html/                           # 웹 루트 디렉토리 (홈 디렉토리)
└── index.html                    # 기본 웹 페이지
```

## 💻 유용한 명령어

### 컨테이너 관리
```bash
# 컨테이너 로그 확인
docker compose logs -f

# 특정 서비스 로그만 보기
docker compose logs -f nginx-ssh

# 컨테이너 재시작
docker compose restart

# 컨테이너 중지
docker compose stop

# 컨테이너 시작
docker compose start

# 컨테이너 완전 종료 및 제거
docker compose down

# 컨테이너 상태 확인
docker compose ps
```

### 컨테이너 내부 접속
```bash
# Bash 셸로 접속
docker exec -it nginx-ssh bash

# 특정 명령어 실행
docker exec nginx-ssh nginx -t          # Nginx 설정 테스트
docker exec nginx-ssh nginx -s reload   # Nginx 설정 리로드
```

### 이미지 관리
```bash
# 이미지 재빌드
docker build -t nginx-ssh-custom:latest .

# 이미지 목록 확인
docker images | grep nginx-ssh

# 이미지 삭제 (컨테이너 중지 후)
docker rmi nginx-ssh-custom:latest
```

### Nginx 관리
```bash
# Nginx 설정 테스트
docker exec nginx-ssh nginx -t

# Nginx 재시작 (설정 변경 후)
docker exec nginx-ssh nginx -s reload

# Nginx 로그 확인
docker exec nginx-ssh tail -f /var/log/nginx/access.log
docker exec nginx-ssh tail -f /var/log/nginx/error.log
```

## 🔒 보안 권장사항

### 1. 강력한 비밀번호 사용
- 최소 12자 이상
- 대소문자, 숫자, 특수문자 조합
- 정기적인 비밀번호 변경

### 2. SSH 키 인증 사용 (권장)
```bash
# 로컬에서 SSH 키 생성
ssh-keygen -t ed25519 -C "your_email@example.com"

# 공개키를 서버에 복사
ssh-copy-id -p 2222 admin@YOUR_SERVER_IP

# SSH 설정에서 비밀번호 인증 비활성화 (선택사항)
# Dockerfile 또는 entrypoint.sh 수정 필요
```

### 3. 방화벽 설정
```bash
# UFW 사용 예시 (Ubuntu)
sudo ufw allow 2222/tcp  # SSH 포트
sudo ufw allow 80/tcp    # HTTP 포트
sudo ufw enable

# 특정 IP만 SSH 허용
sudo ufw allow from 192.168.1.0/24 to any port 2222
```

### 4. Fail2ban 설정 (선택사항)
```bash
# Fail2ban 설치
sudo apt-get install fail2ban

# SSH 보호 활성화
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 5. 정기적인 업데이트
```bash
# 이미지 재빌드 (보안 패치 적용)
docker compose down
docker build -t nginx-ssh-custom:latest .
docker compose up -d
```

### 6. 디스크 공간 모니터링
```bash
# 디스크 사용량 확인
df -h

# Docker 디스크 사용량
docker system df

# 불필요한 데이터 정리
docker system prune -a
```

## 🔧 문제 해결

### 포트가 이미 사용 중인 경우
```bash
# 포트 사용 확인
sudo lsof -i :80
sudo lsof -i :2222

# 프로세스 종료 또는 다른 포트 사용
```

### 컨테이너가 시작되지 않는 경우
```bash
# 로그 확인
docker compose logs

# 컨테이너 상태 확인
docker compose ps

# 컨테이너 재시작
docker compose restart
```

### SSH 접속이 안 되는 경우
```bash
# SSH 서비스 상태 확인
docker exec nginx-ssh service ssh status

# SSH 로그 확인
docker exec nginx-ssh tail -f /var/log/auth.log

# 방화벽 확인
sudo ufw status
```

### Nginx가 시작되지 않는 경우
```bash
# Nginx 설정 테스트
docker exec nginx-ssh nginx -t

# Nginx 로그 확인
docker exec nginx-ssh cat /var/log/nginx/error.log

# 설정 파일 확인
docker exec nginx-ssh cat /etc/nginx/sites-enabled/default
```

### 권한 문제
```bash
# html 디렉토리 권한 확인
ls -la ~/html

# 권한 수정 (필요시)
sudo chown -R $USER:$USER ~/html
sudo chmod -R 755 ~/html
```

### 이미지 빌드 실패
```bash
# Docker 캐시 없이 재빌드
docker build --no-cache -t nginx-ssh-custom:latest .

# 디스크 공간 확인
df -h

# Docker 정리
docker system prune -a
```

## 🔄 재설치 방법

완전히 제거 후 재설치:

```bash
# 1. 컨테이너 중지 및 제거
docker compose down

# 2. 이미지 제거
docker rmi nginx-ssh-custom:latest

# 3. 설정 파일 제거 (선택사항)
rm -f docker-compose.yml Dockerfile default.conf entrypoint.sh .nginx-ssh-config

# 4. 스크립트 재실행
sudo ./install-nginx-ssh.sh
```

## 📝 설정 변경

### SSH 포트 변경
```bash
# 1. docker-compose.yml 수정
nano docker-compose.yml
# ports 섹션에서 SSH 포트 변경

# 2. 컨테이너 재시작
docker compose down
docker compose up -d
```

### HTTP 포트 변경
```bash
# 1. docker-compose.yml 수정
nano docker-compose.yml
# ports 섹션에서 HTTP 포트 변경

# 2. 컨테이너 재시작
docker compose down
docker compose up -d
```

### Nginx 설정 변경
```bash
# 1. default.conf 수정
nano default.conf

# 2. 이미지 재빌드
docker build -t nginx-ssh-custom:latest .

# 3. 컨테이너 재시작
docker compose down
docker compose up -d
```

---

**참고 문서**
- [Nginx 공식 문서](https://nginx.org/en/docs/)
- [Docker 공식 문서](https://docs.docker.com/)
- [OpenSSH 문서](https://www.openssh.com/manual.html)
- [Docker Compose 문서](https://docs.docker.com/compose/)

