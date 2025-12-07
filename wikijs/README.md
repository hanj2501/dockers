# Wiki.js + PostgreSQL 자동 설치 스크립트

Docker를 이용하여 Wiki.js와 PostgreSQL 데이터베이스를 자동으로 설치하고 설정하는 Bash 스크립트입니다.

## 📋 목차

- [Wiki.js란?](#wikijs란)
- [주요 기능](#주요-기능)
- [시스템 요구사항](#시스템-요구사항)
- [설치 방법](#설치-방법)
- [사용 방법](#사용-방법)
- [초기 설정](#초기-설정)
- [생성되는 파일](#생성되는-파일)
- [접속 방법](#접속-방법)
- [Wiki.js 기능](#wikijs-기능)
- [유용한 명령어](#유용한-명령어)
- [백업 및 복원](#백업-및-복원)
- [HTTPS 설정](#https-설정)
- [문제 해결](#문제-해결)
- [라이선스](#라이선스)

## 📖 Wiki.js란?

Wiki.js는 Node.js 기반의 현대적이고 강력한 오픈소스 위키 시스템입니다.

### 주요 특징

- **🎨 현대적인 UI**: 깔끔하고 직관적인 인터페이스
- **✏️ 강력한 편집기**: Markdown, WYSIWYG, Code 편집기 지원
- **🔍 전문 검색**: ElasticSearch, Algolia, PostgreSQL 검색 지원
- **🔐 다양한 인증**: LDAP, OAuth, SAML, Active Directory 등
- **🌍 다국어 지원**: 50개 이상의 언어 지원
- **📝 버전 관리**: Git 연동 및 변경 이력 관리
- **🎯 권한 관리**: 세밀한 사용자 및 그룹 권한 설정
- **🔌 확장성**: 다양한 모듈 및 플러그인 지원

### 사용 사례

- 기술 문서화
- 지식 베이스
- 팀 위키
- 프로젝트 문서
- 개인 노트
- 회사 내부 문서

## 🚀 주요 기능

- ✅ **자동화된 설치**: 모든 설정을 자동으로 구성
- ✅ **PostgreSQL 연동**: 안정적인 데이터베이스 백엔드
- ✅ **버전 선택**: Wiki.js와 PostgreSQL 버전 자유 선택
- ✅ **데이터 영속성**: Docker 볼륨을 통한 데이터 보존
- ✅ **네트워크 격리**: PostgreSQL은 내부 네트워크 전용
- ✅ **즉시 사용 가능**: 설치 후 바로 사용 가능

## 📦 시스템 요구사항

### 최소 요구사항
- **운영체제**: Linux (Ubuntu, Debian, CentOS 등)
- **Docker**: 20.10 이상
- **Docker Compose**: 1.29 이상
- **메모리**: 최소 1GB (권장 2GB 이상)
- **디스크**: 최소 2GB 여유 공간
- **CPU**: 1 Core 이상

### 권장 사양
- **메모리**: 4GB 이상
- **디스크**: 10GB 이상 (문서가 많을 경우)
- **CPU**: 2 Core 이상

## 📥 설치 방법

### 방법 1: 원라인 설치 (추천)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/wikijs/install-wikijs.sh | sudo bash
```

### 방법 2: 수동 다운로드 후 실행

```bash
# 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/wikijs/install-wikijs.sh

# 실행 권한 부여
chmod +x install-wikijs.sh

# 실행
sudo ./install-wikijs.sh
```

## 🎯 사용 방법

### 1. 스크립트 실행

```bash
sudo ./install-wikijs.sh
```

### 2. 대화형 설정

스크립트가 다음 정보를 순차적으로 요청합니다:

#### 컨테이너 설정
- **Wiki.js 컨테이너 이름** (기본값: `wikijs`)
- **PostgreSQL 컨테이너 이름** (기본값: `postgres`)
- **Docker 네트워크 이름** (기본값: `main`)

#### 버전 설정
- **Wiki.js 버전** (기본값: `latest`)
  - 예시: `2`, `2.5`, `latest`
- **PostgreSQL 버전** (기본값: `15-alpine`)
  - 예시: `15-alpine`, `14-alpine`, `13-alpine`

#### 데이터베이스 설정
- **데이터베이스 이름** (기본값: `wiki`)
- **PostgreSQL 사용자 이름** (기본값: `wikijs`)
- **PostgreSQL 비밀번호**
- **PostgreSQL 비밀번호 확인**

#### 포트 설정
- **Wiki.js 웹 포트** (기본값: `3000`)
- **PostgreSQL 외부 노출 여부** (기본값: N)
  - 대부분의 경우 내부 전용으로 충분합니다

### 3. 설정 확인 및 설치

입력한 설정을 확인하고 `y`를 입력하여 설치를 진행합니다.

## 🔧 초기 설정

설치가 완료되면 웹 브라우저에서 초기 설정을 진행해야 합니다.

### 1. Wiki.js 접속

```
http://YOUR_SERVER_IP:3000
```

### 2. 관리자 계정 생성

첫 접속 시 다음 정보를 입력합니다:

1. **관리자 이메일**: 로그인에 사용할 이메일 주소
2. **비밀번호**: 강력한 비밀번호 설정
3. **이름**: 관리자 이름
4. **사이트 URL**: Wiki.js 접속 URL

### 3. 사이트 설정

- **사이트 제목**: 위키 이름
- **설명**: 위키 설명
- **로고**: 사이트 로고 업로드 (선택사항)

### 4. 초기 설정 완료

설정이 완료되면 Wiki.js 대시보드로 이동합니다.

## 📁 생성되는 파일

설치 후 다음 파일과 디렉토리가 생성됩니다:

```
./
├── docker-compose.yml        # Docker Compose 설정 파일
├── .wikijs-config            # 설정 정보 (비밀번호 제외)
├── postgres-data/            # PostgreSQL 데이터 저장 디렉토리
│   └── (PostgreSQL 데이터 파일들)
└── wikijs-data/              # Wiki.js 데이터 저장 디렉토리
    └── (Wiki.js 데이터 파일들)
```

### 파일 상세 설명

#### `docker-compose.yml`
- Wiki.js와 PostgreSQL 컨테이너 정의
- 네트워크 및 볼륨 설정
- 환경 변수 구성
- Health check 설정

#### `.wikijs-config`
- 컨테이너 이름, 네트워크 정보
- 버전 정보
- 포트 설정
- 데이터베이스 정보
- **비밀번호는 포함되지 않음** (보안)

#### `postgres-data/`
- PostgreSQL 데이터베이스 파일 저장
- Docker 볼륨으로 마운트
- 컨테이너 삭제 시에도 데이터 보존

#### `wikijs-data/`
- Wiki.js 데이터 파일 저장
- 컨테이너 삭제 시에도 데이터 보존

## 🌐 접속 방법

### Wiki.js 웹 접속

```
URL: http://YOUR_SERVER_IP:포트번호
예시: http://192.168.1.100:3000
```

### PostgreSQL 직접 접속 (선택사항)

#### 1. 컨테이너 내부에서 접속

```bash
docker exec -it postgres psql -U wikijs -d wiki
```

#### 2. 호스트에서 접속 (외부 포트 노출한 경우)

```bash
psql -h localhost -p 5432 -U wikijs -d wiki
```

#### 3. 같은 네트워크의 다른 컨테이너에서 접속

```bash
psql -h postgres -U wikijs -d wiki
```

## 📝 Wiki.js 기능

### 1. 편집기

Wiki.js는 다양한 편집기를 지원합니다:

- **Markdown**: 가장 인기있는 편집 방식
- **WYSIWYG**: 워드 프로세서 스타일 편집
- **Code**: 코드 편집에 최적화
- **API Docs**: API 문서 작성 특화

### 2. 버전 관리

- 모든 페이지 변경 이력 추적
- Git 저장소 연동 가능
- 이전 버전으로 복원 가능
- 변경 사항 비교 (diff)

### 3. 검색 기능

강력한 검색 엔진 지원:
- PostgreSQL 전문 검색 (기본)
- ElasticSearch
- Algolia
- AWS CloudSearch

### 4. 인증 및 권한

#### 지원하는 인증 방식
- 로컬 인증 (기본)
- LDAP / Active Directory
- OAuth 2.0 (Google, GitHub, Azure 등)
- SAML 2.0
- CAS
- Discord
- Slack

#### 권한 관리
- 사용자별 권한 설정
- 그룹별 권한 설정
- 페이지별 접근 제어
- 읽기/쓰기/관리 권한 분리

### 5. 국제화

- 50개 이상의 언어 지원
- 다국어 콘텐츠 관리
- 언어별 페이지 버전

### 6. 테마

- 기본 테마 제공
- 커스텀 CSS 지원
- 다크 모드 지원

### 7. 통합 기능

- Git 저장소 동기화
- Google Analytics
- Slack 알림
- 웹훅 지원

## 🛠️ 유용한 명령어

### 컨테이너 관리

```bash
# 로그 확인
docker compose logs -f

# Wiki.js 로그만 확인
docker compose logs -f wikijs

# PostgreSQL 로그만 확인
docker compose logs -f postgres

# 컨테이너 상태 확인
docker compose ps

# 서비스 재시작
docker compose restart

# Wiki.js만 재시작
docker compose restart wikijs

# 서비스 중지
docker compose stop

# 서비스 시작
docker compose start

# 서비스 완전 삭제 (데이터 보존)
docker compose down

# 서비스 완전 삭제 (볼륨도 삭제, 데이터 삭제됨)
docker compose down -v
```

### Wiki.js 관리

```bash
# Wiki.js 컨테이너 쉘 접속
docker exec -it wikijs sh

# Wiki.js 설정 파일 확인
docker exec -it wikijs cat /wiki/config.yml

# Wiki.js 버전 확인
docker exec -it wikijs node -v
```

### PostgreSQL 관리

```bash
# PostgreSQL 쉘 접속
docker exec -it postgres psql -U wikijs -d wiki

# 데이터베이스 목록 확인
docker exec -it postgres psql -U wikijs -d wiki -c "\l"

# 테이블 목록 확인
docker exec -it postgres psql -U wikijs -d wiki -c "\dt"

# 데이터베이스 크기 확인
docker exec -it postgres psql -U wikijs -d wiki -c "
SELECT 
    pg_size_pretty(pg_database_size('wiki')) as size;
"

# 연결 상태 확인
docker exec -it postgres psql -U wikijs -d wiki -c "
SELECT 
    datname,
    count(*) as connections
FROM pg_stat_activity
GROUP BY datname;
"
```

## 💾 백업 및 복원

### Wiki.js 전체 백업

#### 방법 1: PostgreSQL 데이터베이스 백업

```bash
# 데이터베이스 백업
docker exec postgres pg_dump -U wikijs wiki > wiki_backup_$(date +%Y%m%d).sql

# 압축 백업
docker exec postgres pg_dump -U wikijs wiki | gzip > wiki_backup_$(date +%Y%m%d).sql.gz
```

#### 방법 2: 데이터 디렉토리 전체 백업

```bash
# 서비스 중지
docker compose stop

# 데이터 디렉토리 백업
tar -czf wiki_full_backup_$(date +%Y%m%d).tar.gz postgres-data/ wikijs-data/

# 서비스 시작
docker compose start
```

### 백업 복원

#### PostgreSQL 데이터베이스 복원

```bash
# 일반 백업 복원
docker exec -i postgres psql -U wikijs wiki < wiki_backup_20241207.sql

# 압축 백업 복원
gunzip < wiki_backup_20241207.sql.gz | docker exec -i postgres psql -U wikijs wiki
```

#### 전체 데이터 복원

```bash
# 서비스 중지 및 삭제
docker compose down

# 기존 데이터 제거
rm -rf postgres-data/ wikijs-data/

# 백업 복원
tar -xzf wiki_full_backup_20241207.tar.gz

# 서비스 시작
docker compose up -d
```

### 자동 백업 스크립트

```bash
#!/bin/bash
# wiki-backup.sh

BACKUP_DIR="/backup/wiki"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# PostgreSQL 백업
docker exec postgres pg_dump -U wikijs wiki | gzip > $BACKUP_DIR/wiki_${DATE}.sql.gz

# 30일 이상 된 백업 파일 삭제
find $BACKUP_DIR -name "wiki_*.sql.gz" -mtime +30 -delete

echo "Backup completed: wiki_${DATE}.sql.gz"
```

**Cron 설정 (매일 새벽 2시 백업):**
```bash
crontab -e

# 다음 줄 추가
0 2 * * * /path/to/wiki-backup.sh >> /var/log/wiki-backup.log 2>&1
```

## 🔒 HTTPS 설정

프로덕션 환경에서는 반드시 HTTPS를 설정해야 합니다.

### 방법 1: Caddy 리버스 프록시 (권장)

**Caddyfile:**
```
wiki.example.com {
    reverse_proxy wikijs:3000
}
```

### 방법 2: Nginx 리버스 프록시

**nginx.conf:**
```nginx
server {
    listen 80;
    server_name wiki.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name wiki.example.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
        proxy_pass http://wikijs:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Let's Encrypt SSL 인증서

```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx

# SSL 인증서 발급
sudo certbot --nginx -d wiki.example.com
```

## 🔍 문제 해결

### Wiki.js가 시작되지 않는 경우

1. **PostgreSQL 상태 확인:**
   ```bash
   docker compose ps
   docker compose logs postgres
   ```

2. **데이터베이스 연결 확인:**
   ```bash
   docker exec -it postgres psql -U wikijs -d wiki
   ```

3. **Wiki.js 로그 확인:**
   ```bash
   docker compose logs wikijs
   ```

### PostgreSQL 연결 오류

**오류:** `FATAL: password authentication failed`

**해결방법:**
1. docker-compose.yml에서 비밀번호 확인
2. PostgreSQL 컨테이너 재시작
   ```bash
   docker compose restart postgres
   ```

### 페이지가 로드되지 않는 경우

1. **방화벽 확인:**
   ```bash
   sudo ufw status
   sudo ufw allow 3000/tcp
   ```

2. **포트 충돌 확인:**
   ```bash
   sudo netstat -tulpn | grep 3000
   ```

3. **컨테이너 상태 확인:**
   ```bash
   docker compose ps
   ```

### 데이터베이스 마이그레이션 실패

```bash
# Wiki.js 컨테이너 재시작
docker compose restart wikijs

# 로그에서 오류 확인
docker compose logs -f wikijs
```

### 관리자 비밀번호를 잊어버린 경우

PostgreSQL에서 직접 비밀번호를 재설정할 수 있습니다:

```bash
# PostgreSQL 쉘 접속
docker exec -it postgres psql -U wikijs wiki

# 비밀번호 재설정 (bcrypt 해시 사용)
# 예: "newpassword"의 해시
UPDATE users 
SET password = '$2a$12$...' 
WHERE email = 'admin@example.com';
```

더 간단한 방법은 Wiki.js를 재설치하는 것입니다.

## ⚙️ 고급 설정

### 이메일 설정

Wiki.js 관리 패널에서 이메일 설정:

1. **Administration** → **Mail** 이동
2. SMTP 서버 정보 입력
3. 테스트 이메일 발송

### Git 동기화 설정

1. **Administration** → **Storage** 이동
2. **Git** 모듈 활성화
3. Git 저장소 URL 입력
4. 인증 정보 설정
5. 동기화 일정 설정

### 검색 엔진 변경

1. **Administration** → **Search Engine** 이동
2. 원하는 검색 엔진 선택
3. 설정 입력
4. Rebuild Index 실행

### 사용자 정의 CSS

1. **Administration** → **Theme** 이동
2. **Code Injection** 섹션
3. Custom CSS 입력

## 📊 성능 최적화

### PostgreSQL 튜닝

**docker-compose.yml 수정:**
```yaml
services:
  postgres:
    command:
      - "postgres"
      - "-c"
      - "max_connections=100"
      - "-c"
      - "shared_buffers=256MB"
      - "-c"
      - "effective_cache_size=1GB"
      - "-c"
      - "maintenance_work_mem=64MB"
```

### Wiki.js 캐싱

Wiki.js는 자동으로 페이지를 캐싱합니다. 추가 설정은 관리 패널에서 가능합니다.

### 리소스 모니터링

```bash
# 컨테이너 리소스 사용량
docker stats wikijs postgres

# 디스크 사용량
du -sh postgres-data/ wikijs-data/
```

## 🔐 보안 권장사항

1. **강력한 비밀번호 사용**
   - PostgreSQL 비밀번호
   - Wiki.js 관리자 비밀번호

2. **방화벽 설정**
   ```bash
   sudo ufw allow 3000/tcp
   sudo ufw enable
   ```

3. **HTTPS 사용** (프로덕션 필수)

4. **정기적인 백업**

5. **PostgreSQL 외부 노출 금지**
   - 내부 네트워크 전용으로 사용

6. **정기적인 업데이트**
   ```bash
   docker compose pull
   docker compose up -d
   ```

7. **2단계 인증 활성화**
   - Administration → Security → 2FA

## 📚 참고 문서

- [Wiki.js 공식 문서](https://docs.requarks.io/)
- [Wiki.js GitHub](https://github.com/requarks/wiki)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [Docker 공식 문서](https://docs.docker.com/)
