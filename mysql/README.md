# MySQL + phpMyAdmin 자동 설치 스크립트

Docker를 이용하여 MySQL 데이터베이스와 phpMyAdmin 웹 관리 도구를 자동으로 설치하고 설정하는 Bash 스크립트입니다.

## 📋 목차

- [주요 기능](#주요-기능)
- [시스템 요구사항](#시스템-요구사항)
- [설치 방법](#설치-방법)
- [사용 방법](#사용-방법)
- [보안 기능](#보안-기능)
- [버전 호환성](#버전-호환성)
- [생성되는 파일](#생성되는-파일)
- [접속 방법](#접속-방법)
- [유용한 명령어](#유용한-명령어)
- [문제 해결](#문제-해결)
- [라이선스](#라이선스)

## 🚀 주요 기능

- ✅ **자동화된 설치**: 모든 설정을 자동으로 구성
- ✅ **버전 선택**: MySQL과 phpMyAdmin 버전 자유 선택
- ✅ **자동 호환성 체크**: MySQL 버전에 맞는 phpMyAdmin 버전 자동 추천
- ✅ **강화된 보안**: Docker 네트워크 기반 Root 접근 제어
- ✅ **한글 지원**: UTF-8 완벽 지원
- ✅ **초기 데이터베이스 생성**: 설치 시 데이터베이스 자동 생성
- ✅ **데이터 영속성**: Docker 볼륨을 통한 데이터 보존

## 📦 시스템 요구사항

- **운영체제**: Linux (Ubuntu, Debian, CentOS 등)
- **Docker**: 20.10 이상
- **Docker Compose**: 1.29 이상
- **메모리**: 최소 512MB (권장 1GB 이상)
- **디스크**: 최소 1GB 여유 공간

## 📥 설치 방법

### 방법 1: 원라인 설치 (추천)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/mysql/install-mysql.sh | sudo bash
```

### 방법 2: 수동 다운로드 후 실행

```bash
# 스크립트 다운로드
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/mysql/install-mysql.sh

# 실행 권한 부여
chmod +x install-mysql.sh

# 실행
sudo ./install-mysql.sh
```

## 🎯 사용 방법

### 1. 스크립트 실행

```bash
sudo ./install-mysql.sh
```

### 2. 대화형 설정

스크립트가 다음 정보를 순차적으로 요청합니다:

#### 컨테이너 설정
- **MySQL 컨테이너 이름** (기본값: `mysql`)
- **phpMyAdmin 컨테이너 이름** (기본값: `phpmyadmin`)
- **Docker 네트워크 이름** (기본값: `main`)

#### 버전 설정
- **MySQL 버전** (기본값: `latest`)
  - 예시: `8.0`, `8.4`, `5.7`, `latest`
- **phpMyAdmin 버전** (MySQL 버전에 따라 자동 추천)
  - 예시: `5.2`, `5.1`, `4.9`, `latest`

#### 보안 설정
- **MySQL Root 비밀번호**
- **MySQL Root 비밀번호 확인**

#### 데이터베이스 설정
- **데이터베이스 이름** (기본값: `mydb`)
- **MySQL 사용자 이름** (기본값: `myuser`)
- **MySQL 사용자 비밀번호**
- **MySQL 사용자 비밀번호 확인**

#### 포트 설정
- **MySQL 포트** (기본값: `3306`)
- **phpMyAdmin 웹 포트** (기본값: `8080`)

### 3. 설정 확인 및 설치

입력한 설정을 확인하고 `y`를 입력하여 설치를 진행합니다.

## 🔒 보안 기능

### Root 계정 접근 제어

이 스크립트는 MySQL Root 계정의 보안을 강화합니다:

1. **네트워크 기반 접근 제어**
   - Root 계정은 **지정된 Docker 네트워크 서브넷 내부에서만** 접속 가능
   - 외부(%)에서 Root 직접 접속 불가능
   - 같은 Docker 네트워크의 컨테이너에서만 Root 접속 가능

2. **일반 사용자 계정**
   - 외부 접속용 일반 사용자 계정 자동 생성
   - 지정된 데이터베이스에 대한 권한만 부여

3. **접근 방식**
   ```
   ✅ 허용: 같은 Docker 네트워크 내부 → Root 접속
   ✅ 허용: docker exec 명령어 → Root 접속  
   ✅ 허용: phpMyAdmin (같은 네트워크) → Root 접속
   ✅ 허용: 외부 → 일반 사용자 접속
   ❌ 차단: 외부 → Root 직접 접속
   ```

### 보안 설정 파일

- `.mysql-config` 파일에는 비밀번호가 **저장되지 않습니다**
- 파일 권한 자동으로 `600`으로 설정 (소유자만 읽기/쓰기 가능)

## 🔄 버전 호환성

### MySQL과 phpMyAdmin 호환성 매트릭스

| MySQL 버전 | 권장 phpMyAdmin 버전 | 지원 여부 | 비고 |
|-----------|-------------------|---------|------|
| 5.5.x | 4.9 | ✅ | phpMyAdmin 5.x와 호환성 제한 |
| 5.6.x | 5.1 | ✅ | 안정적인 호환성 |
| 5.7.x | 5.2 | ✅ | 최적 호환성, 권장 조합 |
| 8.0.x | latest | ✅ | 모든 최신 기능 지원 |
| 8.4.x | latest | ✅ | 최신 버전 완벽 호환 |
| latest | latest | ✅ | 항상 최신 버전 사용 |

### 자동 버전 추천

스크립트는 입력한 MySQL 버전에 따라 최적의 phpMyAdmin 버전을 자동으로 추천합니다:

```
MySQL 5.7 입력 시:
phpMyAdmin 버전을 입력하세요 (기본값: 5.2, MySQL 5.7 호환):
ℹ MySQL 5.7에 권장되는 버전: 5.2
```

## 📁 생성되는 파일

설치 후 다음 파일과 디렉토리가 생성됩니다:

```
./
├── docker-compose.yml        # Docker Compose 설정 파일
├── .mysql-config             # 설정 정보 (비밀번호 제외)
├── mysql-data/               # MySQL 데이터 저장 디렉토리
│   └── (MySQL 데이터 파일들)
└── mysql-init/               # 초기화 SQL 스크립트
    └── 00-security.sql       # Root 계정 보안 설정
```

### 파일 상세 설명

#### `docker-compose.yml`
- MySQL과 phpMyAdmin 컨테이너 정의
- 네트워크 및 볼륨 설정
- 환경 변수 구성

#### `.mysql-config`
- 컨테이너 이름, 네트워크 정보
- 버전 정보
- 포트 설정
- 데이터베이스 및 사용자 정보
- **비밀번호는 포함되지 않음** (보안)

#### `mysql-data/`
- MySQL 데이터베이스 파일 저장
- Docker 볼륨으로 마운트
- 컨테이너 삭제 시에도 데이터 보존

#### `mysql-init/00-security.sql`
- Root 계정 접근 제어 설정
- Docker 네트워크 서브넷 기반 권한 설정
- 초기화 시 자동 실행

## 🌐 접속 방법

### phpMyAdmin 웹 접속

```
URL: http://YOUR_SERVER_IP:포트번호
예시: http://192.168.1.100:8080
```

**로그인 방법:**

1. **Root 계정 로그인** (관리자, 네트워크 내부)
   - 사용자: `root`
   - 비밀번호: 설정한 Root 비밀번호

2. **일반 사용자 로그인** (외부 접속 가능)
   - 사용자: 설정한 사용자 이름
   - 비밀번호: 설정한 사용자 비밀번호

### MySQL 직접 접속

#### 1. 호스트에서 일반 사용자로 접속

```bash
mysql -h localhost -P 3306 -u myuser -p
```

#### 2. 컨테이너 내부에서 Root 접속

```bash
docker exec -it mysql mysql -u root -p
```

#### 3. 같은 네트워크의 다른 컨테이너에서 접속

**Root 접속 (네트워크 내부):**
```bash
mysql -h mysql -u root -p
```

**일반 사용자 접속:**
```bash
mysql -h mysql -u myuser -p
```

### 애플리케이션 연결 문자열

```
Host: mysql (또는 localhost:3306)
Port: 3306
Database: mydb
User: myuser (일반 작업) 또는 root (관리 작업, 네트워크 내부만)
Password: 설정한 비밀번호
```

## 🛠️ 유용한 명령어

### 컨테이너 관리

```bash
# 로그 확인
docker compose logs -f

# MySQL 로그만 확인
docker compose logs -f mysql

# phpMyAdmin 로그만 확인
docker compose logs -f phpmyadmin

# 컨테이너 상태 확인
docker compose ps

# 서비스 재시작
docker compose restart

# 서비스 중지
docker compose stop

# 서비스 시작
docker compose start

# 서비스 완전 삭제 (데이터 보존)
docker compose down

# 서비스 완전 삭제 (볼륨도 삭제, 데이터 삭제됨)
docker compose down -v
```

### MySQL 관리

```bash
# MySQL 쉘 접속 (Root)
docker exec -it mysql mysql -u root -p

# MySQL 쉘 접속 (일반 사용자)
docker exec -it mysql mysql -u myuser -p

# Bash 쉘 접속
docker exec -it mysql bash

# Root 계정 권한 확인
docker exec -it mysql mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='root';"

# 데이터베이스 목록 확인
docker exec -it mysql mysql -u root -p -e "SHOW DATABASES;"

# 사용자 목록 확인
docker exec -it mysql mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
```

### 백업 및 복원

```bash
# 전체 데이터베이스 백업
docker exec mysql mysqldump -u root -p --all-databases > backup_$(date +%Y%m%d).sql

# 특정 데이터베이스 백업
docker exec mysql mysqldump -u root -p mydb > mydb_backup_$(date +%Y%m%d).sql

# 백업 복원
docker exec -i mysql mysql -u root -p < backup_20241207.sql

# 특정 데이터베이스 복원
docker exec -i mysql mysql -u root -p mydb < mydb_backup_20241207.sql
```

### 네트워크 관리

```bash
# 네트워크 정보 확인
docker network inspect main

# 네트워크에 연결된 컨테이너 확인
docker network inspect main | grep "Name"

# 네트워크 서브넷 확인
docker network inspect main -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

## 🔍 문제 해결

### MySQL 컨테이너가 시작되지 않는 경우

1. **로그 확인:**
   ```bash
   docker compose logs mysql
   ```

2. **포트 충돌 확인:**
   ```bash
   sudo netstat -tulpn | grep 3306
   ```
   포트가 이미 사용 중이면 `.mysql-config`에서 포트 변경 후 재시작

3. **권한 문제:**
   ```bash
   sudo chown -R 999:999 mysql-data/
   ```

### phpMyAdmin에 접속할 수 없는 경우

1. **컨테이너 상태 확인:**
   ```bash
   docker compose ps
   ```

2. **방화벽 확인:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080/tcp
   ```

3. **로그 확인:**
   ```bash
   docker compose logs phpmyadmin
   ```

### Root로 외부에서 접속이 안 되는 경우

이것은 **정상입니다**. 보안을 위해 Root는 Docker 네트워크 내부에서만 접속 가능하도록 설정되어 있습니다.

**해결 방법:**
1. **일반 사용자 사용** (권장):
   ```bash
   mysql -h localhost -P 3306 -u myuser -p
   ```

2. **docker exec 사용**:
   ```bash
   docker exec -it mysql mysql -u root -p
   ```

3. **같은 네트워크의 컨테이너에서 접속**:
   ```bash
   mysql -h mysql -u root -p
   ```

### 데이터베이스 연결 오류

1. **컨테이너 이름 확인:**
   ```bash
   docker ps
   ```

2. **네트워크 연결 확인:**
   ```bash
   docker network inspect main
   ```

3. **사용자 권한 확인:**
   ```bash
   docker exec -it mysql mysql -u root -p -e "SHOW GRANTS FOR 'myuser'@'%';"
   ```

### 비밀번호를 잊어버린 경우

1. **docker-compose.yml에서 환경 변수 확인** (설치 직후라면)

2. **비밀번호 재설정:**
   ```bash
   docker exec -it mysql mysql -u root -p
   ALTER USER 'myuser'@'%' IDENTIFIED BY 'new_password';
   FLUSH PRIVILEGES;
   ```

## ⚙️ 고급 설정

### 커스텀 MySQL 설정

`mysql-data/my.cnf` 파일을 생성하여 커스텀 설정 추가:

```ini
[mysqld]
max_connections=500
innodb_buffer_pool_size=1G
```

### 추가 데이터베이스 생성

```bash
docker exec -it mysql mysql -u root -p

CREATE DATABASE newdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON newdb.* TO 'myuser'@'%';
FLUSH PRIVILEGES;
```

### SSL 설정

보안 연결을 위한 SSL 인증서 설정은 [MySQL 공식 문서](https://dev.mysql.com/doc/refman/8.0/en/using-encrypted-connections.html)를 참조하세요.

## 🔐 보안 권장사항

1. **방화벽 설정**
   ```bash
   # MySQL 포트는 필요한 IP만 허용
   sudo ufw allow from 192.168.1.0/24 to any port 3306
   
   # phpMyAdmin은 관리자 IP만 허용
   sudo ufw allow from 192.168.1.10 to any port 8080
   ```

2. **정기적인 백업**
   - 매일 자동 백업 스크립트 설정
   - 백업 파일을 안전한 외부 저장소에 보관

3. **강력한 비밀번호 사용**
   - 최소 12자 이상
   - 대문자, 소문자, 숫자, 특수문자 조합

4. **정기적인 업데이트**
   ```bash
   docker compose pull
   docker compose up -d
   ```

5. **불필요한 사용자 제거**
   ```bash
   docker exec -it mysql mysql -u root -p
   DROP USER 'unused_user'@'%';
   ```

## 📚 참고 문서

- [MySQL 공식 문서](https://dev.mysql.com/doc/)
- [phpMyAdmin 공식 문서](https://docs.phpmyadmin.net/)
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
