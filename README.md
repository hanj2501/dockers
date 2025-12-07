# Linux Server Setup Script

리눅스 서버 초기 설정을 자동화하는 스크립트입니다.

## 🚀 기능

이 스크립트는 다음 작업을 자동으로 수행합니다:

- ✅ **타임존 설정**: 서버 시간을 `Asia/Seoul`로 설정
- ✅ **Docker 설치**: 공식 설치 스크립트를 사용한 최신 Docker 설치
- ✅ **Docker Compose 설치**: Docker와 함께 자동 설치
- ✅ **사용자 권한 설정**: docker 그룹에 사용자 추가 (sudo 없이 Docker 사용)

## 📋 요구사항

- **운영체제**: Ubuntu, Debian, CentOS, RHEL 등 주요 Linux 배포판
- **권한**: root (sudo) 권한 필요
- **네트워크**: 인터넷 연결 필요

## 📥 설치 및 사용 방법

### ⚡ 빠른 설치 (원라인 명령어 - 권장)

```bash
# curl 사용
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh | sudo bash
```

```bash
# wget 사용
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh | sudo bash
```

> 💡 **팁**: 위 명령어는 스크립트를 다운로드하고 즉시 실행합니다.

---

### 📝 단계별 설치 (스크립트 확인 후 실행)

스크립트 내용을 먼저 확인하고 싶다면:

#### 방법 1: wget 사용

```bash
# 1. 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh

# 2. 내용 확인 (선택사항)
cat init_setup.sh

# 3. 실행 권한 부여
chmod +x init_setup.sh

# 4. 스크립트 실행
sudo ./init_setup.sh
```

#### 방법 2: curl 사용

```bash
# 1. 스크립트 다운로드
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/init_setup.sh

# 2. 내용 확인 (선택사항)
cat init_setup.sh

# 3. 실행 권한 부여
chmod +x init_setup.sh

# 4. 스크립트 실행
sudo ./init_setup.sh
```

## 🎯 실행 화면

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          Linux Server Setup Script                           ║
║          타임존 설정 + Docker 설치                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════
  타임존 설정
═══════════════════════════════════════════════════════════

ℹ 현재 타임존 확인 중...
ℹ 현재 타임존: UTC
⚠ 타임존을 Asia/Seoul로 변경합니다...
✓ 타임존이 Asia/Seoul로 설정되었습니다.
ℹ 현재 시간: 2025년 12월 07일 토요일 15:30:00 KST
```

## ✨ 주요 특징

### 1. 스마트한 중복 설치 방지
- 이미 설치된 구성 요소는 건너뜁니다
- 불필요한 재설치를 방지합니다

### 2. 안전한 설치
- 공식 Docker 설치 스크립트 사용 (`https://get.docker.com/`)
- 에러 발생 시 자동 중단 (`set -e`)
- 모든 단계에서 명확한 피드백 제공

### 3. 사용자 친화적
- 컬러풀한 출력으로 진행 상황 파악
- 각 단계별 성공/실패 상태 표시
- 최종 요약 및 다음 단계 안내

## 📝 설치 후 작업

스크립트 실행 후 다음 작업을 수행하세요:

### 1. 로그아웃 후 재로그인
Docker 그룹 권한을 적용하려면 로그아웃 후 다시 로그인해야 합니다.

```bash
exit  # 현재 세션 종료 후 재접속
```

### 2. Docker 설치 확인

```bash
# Docker 버전 확인
docker --version

# Docker 테스트 실행
docker run hello-world

# Docker Compose 버전 확인
docker compose version
```

### 3. Docker 상태 확인

```bash
# Docker 서비스 상태
systemctl status docker

# 실행 중인 컨테이너 확인
docker ps
```

## 🛠️ 유용한 Docker 명령어

### 기본 명령어
```bash
# Docker 정보 확인
docker info

# 이미지 목록
docker images

# 컨테이너 목록 (전체)
docker ps -a

# Docker 로그 확인
docker logs [컨테이너ID]
```

### Docker Compose 명령어
```bash
# 서비스 시작
docker compose up -d

# 서비스 중지
docker compose down

# 로그 확인
docker compose logs -f

# 서비스 상태
docker compose ps
```

### 시스템 관리
```bash
# 사용하지 않는 리소스 정리
docker system prune -a

# 디스크 사용량 확인
docker system df
```

## 🔧 트러블슈팅

### 문제 1: "Permission denied" 오류

**원인**: sudo 권한 없이 실행  
**해결**: `sudo ./init_setup.sh`로 실행

### 문제 2: Docker 명령어 실행 시 권한 오류

**원인**: docker 그룹 권한이 아직 적용되지 않음  
**해결**: 로그아웃 후 재로그인

### 문제 3: 설치 스크립트 다운로드 실패

**원인**: 네트워크 연결 문제  
**해결**: 
- 인터넷 연결 확인
- 방화벽 설정 확인
- DNS 설정 확인

## 📄 스크립트 상세 동작

### 1. Root 권한 확인
- EUID를 확인하여 root 권한 검증
- 권한 없으면 에러 메시지 출력 후 종료

### 2. 타임존 설정
- 현재 타임존 확인 (`timedatectl` 또는 `/etc/timezone`)
- `Asia/Seoul`이 아닌 경우 자동 변경
- 변경 후 현재 시간 표시

### 3. Docker 설치 확인
- `docker --version` 명령어로 설치 여부 확인
- 설치되지 않은 경우:
  - `https://get.docker.com/` 스크립트 다운로드
  - Docker 설치 실행
  - systemd 서비스 활성화

### 4. 사용자 권한 설정
- 현재 사용자를 `docker` 그룹에 추가
- sudo 없이 Docker 명령어 실행 가능

### 5. Docker Compose 확인
- `docker compose version` 명령어로 확인
- 최신 Docker는 Compose V2가 기본 포함

## 🔒 보안 고려사항

- ✅ 공식 Docker 설치 스크립트 사용
- ✅ HTTPS를 통한 안전한 다운로드
- ✅ Root 권한 필수로 무단 실행 방지
- ⚠️ docker 그룹은 root와 동등한 권한을 가지므로 신뢰할 수 있는 사용자만 추가

## 📚 참고 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [Docker 설치 가이드](https://docs.docker.com/engine/install/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Docker 보안 가이드](https://docs.docker.com/engine/security/)

