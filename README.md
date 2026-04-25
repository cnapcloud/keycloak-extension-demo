# Keycloak Extension Demo

Keycloak은 오픈소스 IAM(Identity and Access Management) 솔루션으로, 로그인·회원가입·소셜 연동 등 인증 인프라를 별도 구현 없이 빠르게 구축할 수 있도록 지원합니다. 그러나 실제 서비스에서는 ID 찾기, SMS OTP, 간편인증, 약관 동의, 휴면 계정 관리와 같은 기능이 필수적으로 요구되며, 이는 기본 제공 범위를 넘어서는 영역이기 때문에 SPI(Service Provider Interface)를 통한 확장이 필요합니다.

<!--more-->
이 프로젝트에서는 Keycloak 26.5를 기반으로 이미 개발된 SPI를 활용해 데모 환경을 구성하고, 확장된 인증 흐름에서 제공되는 다양한 기능과 그 구성 방법에 대해 살펴봅니다.

설치 없이 바로 체험하려면 CNAPCloud의 [GitOps 대시보드](https://cnapcloud.com/gitops/) 로그인 페이지에서 동일한 구성을 확인할 수 있습니다.
로그인 후 [Keycloak React 데모](https://react-keycloak.cnapcloud.com)에 접속하면 SSO로 바로 연결되는 것도 확인할 수 있습니다. 이 서비스의 운영 시간은 **09:30 ~ 21:00 KST**입니다.

---

## 목차

1. [실행 방법](#1-실행-방법)
2. [서비스 접속 URL](#2-서비스-접속-url)
3. [Keycloak React 데모](#3-keycloak-react-데모)
4. [Admin Console](#4-admin-console)
5. [데모 환경 구성](#5-데모-환경-구성)
6. [환경 변수 설정](#6-환경-변수-설정)
7. [Make 명령어](#7-make-명령어)
8. [참고 자료](#8-참고-자료)

---

## 1. 실행 방법

데모 환경은 Docker Desktop만 설치되어 있으면 별도의 추가 설정 없이 실행할 수 있습니다. 본 예제는 MacOS 환경에서 Docker Desktop 4.67.0 버전 기준으로 검증되었습니다.

```bash
git clone https://github.com/cnapcloud/keycloak-extension-demo.git
cd keycloak-extension-demo
make up
```

처음 실행 시 Keycloak 기동까지 **약 2~3분**이 소요됩니다. 이 시간 동안 내부적으로 다음과 같은 작업이 순차적으로 진행됩니다.

```
postgres      → DB 준비
keycloak-init → SPI JAR 복사
keycloak      → 서버 기동
keycloak-cli  → cnap Realm 생성 + 초기 관리자 계정 등록
그 외          → rabbitmq, mailhog, keycloak-user-storage, react-keycloak-demo, inicis-mock-server
```

준비가 완료되면 아래 주소들로 접속할 수 있습니다.

---

## 2. 서비스 접속 URL

| 서비스 | 주소 | 설명 |
|---|---|---|
| **React 인증 데모** | http://localhost:5173 | 로그인·회원가입·간편인증 E2E 체험 |
| **Keycloak** | http://localhost:8080 | Keycloak 서버 |
| **간편인증 Mock** | http://localhost:9091 | 이니시스 인증 Mock 서버 |
| **Mailhog** | http://localhost:8025 | 발송된 이메일 확인 |
| **RabbitMQ** | http://localhost:15672 | 사용자 이벤트 메시지 확인 (`admin` / `password`) |
| **User Storage** | http://localhost:8090 | 외부 사용자 저장소 REST API |
| **User Storage DB** | http://localhost:8090/h2-console | H2 DB 스키마·데이터 조회<br>JDBC URL: `jdbc:h2:mem:testdb`<br>ID: `sa` / PW: `password` |

---

## 3. Keycloak React 데모

http://localhost:5173 을 열면 실제 로그인 화면이 나옵니다.

> 개발 환경에서는 OTP 입력란에 **`000000`** 을 입력하면 항상 통과됩니다. (`OTP_DEV_MODE=true`)
> 이메일로 OTP를 전송한 경우, [Mailhog](http://localhost:8025) 수신함에서 확인한 번호를 사용할 수도 있습니다.

### 로그인

1. 아이디 + 비밀번호 입력 (`admin` / `password`)
2. OTP 인증 — SMS 또는 이메일 (`000000`)
3. 약관 미동의 상태면 약관 동의 화면이 먼저 뜹니다

### 간편인증 (KG Inicis)

1. 로그인 화면에서 **간편인증** 버튼 클릭
2. Mock 서버(http://localhost:9091) 인증 페이지로 이동
3. 사용자(홍기동) 선택 후 **인증 성공** 버튼 클릭
4. 동일 전화번호로 가입된 계정(admin)과 연계 확인 후 **연계 추가** 클릭
5. 로그인 완료

> 간편인증은 이미 가입된 사용자와 연동하는 흐름입니다. 먼저 일반 회원가입을 완료한 후 연동하세요.

### 카카오 / 네이버 로그인

> Admin Console → **Identity Providers** 에서 카카오·네이버 OAuth Client ID 및 Secret을 설정한 후에만 사용할 수 있습니다.
> 설정 방법은 [설치 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/02-installation.md) 10절을 참고하세요.

1. 로그인 화면에서 **카카오** 또는 **네이버** 버튼 클릭
2. 각 소셜 서비스 OAuth 인증 완료
3. 가입 시 사용한 이메일과 일치하는 계정에 자동 연동

### 회원가입

1. 약관 동의 (필수 / 선택 구분)
2. 아이디 · 이메일 · 전화번호 · 비밀번호 입력
3. 이메일 또는 SMS OTP 인증

### ID 찾기

1. 이메일 또는 전화번호 입력
2. OTP 인증 후 아이디 확인

### 비밀번호 찾기

1. 아이디(username) 입력
2. OTP 인증 (이메일 / SMS 선택)
3. 새 비밀번호 입력

### 사용자 프로파일

로그인 후 계정 페이지에서 커스텀 속성을 확인하고 수정할 수 있습니다. 속성 목록은 [Admin Console → 사용자 프로파일](#사용자-프로파일-user-profile)을 참고하세요.

---

## 4. Admin Console

http://localhost:8080 → **Administration Console** → Realm: **`cnap`**

- ID: `admin` / PW: `password`

이 데모의 핵심은 Admin Console에 등록된 Extension 설정들입니다.

### Authentication Flow

**Authentication → Flows** 에서 아래 커스텀 플로우를 확인할 수 있습니다.

| Flow | 적용 위치 | 설명 |
|---|---|---|
| `browser-otp` | Browser flow | 로그인 OTP + 휴면 계정 차단 |
| `registration-term` | Registration flow | 회원가입 시 약관 동의 수집 |
| `reset credentials-otp` | Reset credentials flow | 비밀번호 재설정 OTP |

### Required Actions

**Authentication → Required Actions** 에서 확인합니다.

- `Terms and Marketing Consent` — 신규 사용자에게 자동으로 할당되는 약관·마케팅 동의 액션
- `Reactivate Dormant Account` — 휴면 계정 재활성화 액션 (Dormant Check가 트리거)

### 이벤트 리스너

**Realm Settings → Events → Event listeners** 에 아래 리스너가 등록되어 있습니다.

- `last-login-tracker` — 로그인 성공마다 `lastLoginDate` 속성 자동 업데이트
- `user-event-publisher` — 사용자 생성·수정·삭제 이벤트를 RabbitMQ로 발행
- `metrics-listener` — Keycloak 이벤트를 Prometheus 메트릭으로 노출

> RabbitMQ에서 사용자 변경 이벤트를 수신하려면 [RabbitMQ 관리 UI](http://localhost:15672)에 `admin` / `password` 로 로그인합니다.
> `user.account` 큐를 생성하고, exchange에 `user.account.*` 라우팅 키로 바인딩하면 모든 사용자 관련 메시지가 `user.account` 큐로 수신됩니다.

### User Federation

**User Federation** 에 세 가지 Provider가 등록되어 있습니다.

- `dormant-account-scheduler` — 365일 미접속 시 휴면 전환, 90일 후 계정 삭제
- `terms-change-notifier` — 약관 변경 사전 고지 스케줄러
- `REST` — 외부 User Storage API 연동 (http://localhost:8090)

### 소셜 로그인 (Identity Provider)

**Identity Providers** 에서 카카오, 네이버, 이니시스 간편인증 설정을 볼 수 있습니다.

소셜 로그인은 기존 계정과의 **연동** 방식으로 동작합니다. 이메일(카카오·네이버) 또는 전화번호(이니시스)로 가입된 계정을 찾아 자동으로 연결합니다.

### 테마 (Theme)

**Realm Settings → Themes** 에서 로그인·계정 화면의 테마를 설정합니다.

| 항목 | 기본값 | 설명 |
|---|---|---|
| Login theme | `keycloak.ext-dark` | 로그인·회원가입·OTP 등 인증 화면 |
| Account theme | (기본값) | 사용자 계정 관리 페이지 |
| Admin theme | (기본값) | Admin Console |
| Email theme | `keycloak.ext` | 발송 이메일 템플릿 |

### 다국어 (Localization)

**Realm Settings → Localization** 에서 지원 언어와 기본 언어를 설정합니다.

- **Internationalization**: `Enabled`
- **Supported locales**: `ko`, `en`
- **Default locale**: `ko`

### 사용자 프로파일 (User Profile)

**Realm Settings → User profile** 에서 커스텀 속성을 확인하고 편집할 수 있습니다.

**User Profile 스키마 등록 속성**

| 속성 | 필수 | 설명 |
|---|---|---|
| `username` | ✓ | 아이디 |
| `email` | ✓ | 이메일 |
| `firstName` | ✓ | 이름 |
| `lastName` | ✓ | 성 |
| `phoneNumber` | ✓ | 전화번호 — OTP 및 간편인증 연동에 사용 |
| `otpMethod` | ✓ | OTP 수신 방식 (`SMS` / `EMAIL` / `SKIP`), select 입력 |

**SPI 확장이 런타임에 직접 설정하는 속성** 

| 속성 | 설정 주체 | 설명 |
|---|---|---|
| `termsAgreed` | `Terms and Marketing Consent` | 필수 약관 동의 여부 |
| `marketingAgreed` | `Terms and Marketing Consent` | 마케팅 수신 동의 여부 |
| `lastLoginDate` | `last-login-tracker` | 마지막 로그인 일시 (자동 갱신) |
| `dormant` | `dormant-account-scheduler` | 휴면 계정 여부 (자동 설정) |

---

## 5. 데모 환경 구성

전체 데모 환경은 Docker Compose 기반으로 구성되어 있으며, 각 서비스는 인증 흐름, 메시지 처리, 외부 연동, 그리고 데모 UI까지 포함한 통합 실행 환경을 제공합니다. 구성 파일은 [compose.yaml](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docker/compose.yaml)에서 확인할 수 있습니다.

### 서비스 구성

| 서비스 | 포트 | 역할 |
|---|---|---|
| `postgres` | — | Keycloak DB |
| `keycloak-init` | — | SPI JAR를 Keycloak 컨테이너로 복사 |
| `keycloak` | 8080, 9000, 8000 | Keycloak 서버 (HTTP / Health / Debug) |
| `keycloak-cli` | — | cnap Realm 생성 및 초기 관리자 계정 등록 |
| `rabbitmq` | 5672, 15672 | 사용자 이벤트 메시지 브로커 (AMQP / Management UI) |
| `mailhog` | 1025, 8025 | 이메일 수신 Mock (SMTP / Web UI) |
| `keycloak-user-storage` | 8090 | 외부 User Storage REST API (H2 in-memory DB) |
| `react-keycloak-demo` | 5173 | React 인증 데모 앱 |
| `inicis-mock-server` | 9091 | 이니시스 간편인증 Mock 서버 (keycloak 네트워크 공유) |

### 기동 순서

데모 환경의 서비스는 `depends_on` 조건에 따라 아래 순서로 기동됩니다. 처음 실행 시 Keycloak이 완전히 뜨기까지 **약 2~3분**이 소요됩니다.

```
postgres ──────────────────────────┐
keycloak-init ─────────────────────+──→ keycloak ──────────┐
                                                           ├──→ keycloak-cli
keycloak-user-storage ─────────────────────────────────────┘

rabbitmq / mailhog / react-keycloak-demo / inicis-mock-server   (독립 기동)
```

### 볼륨 및 설정 파일

| 경로 | 설명 |
|---|---|
| `docker/compose.yaml` | 서비스 전체 구성 |
| `docker/config/realm-export.json` | cnap Realm 초기 설정 (keycloak-cli가 import) |
| `docker/terms-content/` | 이용약관 HTML 파일 (Realm / 버전 / 언어 경로 구조) |
| `docker/data/` | 런타임 데이터 (postgres, rabbitmq 영속성) |

약관 파일은 수정 후 Keycloak을 재시작하면 반영됩니다.

```
docker/terms-content/
  cnap/
    1.0/ko/
      service.html
      privacy_required.html
      privacy_optional.html
      marketing.html
    2026-04-10/ko/
      service.html
    2026-04-11/ko/
      service.html
```

---

## 6. 환경 변수 설정

compose.yaml 파일에서 keycloak 서비스는 컨테이너 실행 시 필요한 설정값을 environment 블록으로 전달하도록 구성되어 있습니다. 해당 설정을 통해 Keycloak의 초기 관리자 계정, 데이터베이스 연결, 그리고 OTP 및 이벤트 처리와 같은 인증 관련 주요 동작 옵션들이 정의됩니다. 아래는 이 중 일부 핵심 설정입니다.

| 변수 | 기본값 | 설명 |
|---|---|---|
| `OTP_DEV_MODE` | `true` | `000000`으로 OTP 통과 — **운영에서는 반드시 제거** |
| `OTP_CODE_LIFESPAN_SECONDS` | `300` | 인증코드 유효 시간(초) |
| `OTP_RATE_LIMIT_MAX_ATTEMPTS` | `5` | OTP 최대 시도 횟수 |
| `OTP_RATE_LIMIT_LOCKOUT_MINUTES` | `30` | 초과 시 잠금 시간(분) |
| `SMS_PROVIDER` | `aws_sns_x` | 실 SMS: `aws_sns` / 현재는 더미(fallback) |
| `USER_EVENT_CHANNEL` | `rabbitmq` | 이벤트 채널 (`rabbitmq` \| `kafka` \| `redis` \| 미설정 시 log-only) |

---

## 7. Make 명령어

데모 환경은 Docker Compose를 기반으로 여러 서비스를 함께 실행하므로, 개발 및 테스트 편의성을 위해 Makefile을 통해 주요 작업을 간단하게 수행할 수 있도록 구성되어 있습니다.

```bash
make up                      # 전체 서비스 시작 (백그라운드)
make down                    # 전체 서비스 중지 및 컨테이너 제거
make clean                   # 컨테이너 + 볼륨 + 이미지 + data/ 전체 삭제

make up-svc SVC=keycloak     # 단일 서비스만 시작 (의존성 제외)
make down-svc SVC=keycloak   # 단일 서비스만 중지 및 제거

make restart                 # 전체 재시작
make logs                    # 전체 로그 스트리밍
make ps                      # 서비스 상태 확인
```

---

## 8. 참고 자료

데모 환경 구성과 기능 이해를 돕기 위해 관련 문서와 연계 저장소를 함께 제공합니다. 각 문서는 SPI 기반 확장 기능, 설치 및 설정, 사용자/개발자 가이드 등 역할별로 분리되어 있습니다.

### 가이드

- [주요 기능 소개](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/01-features.md)
- [SPI 상세 설치 및 Admin Console 설정 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/02-installation.md)
- [사용자 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/03-user_guide.md)
- [개발자 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/04-developer_guide.md)
- [휴면 계정 테스트 런북](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/05-dormant-account-test-runbook.md)
- [User Storage REST API 연동 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/06-usp-integration-guide.md)
- [이용약관 운영 가이드](https://github.com/cnapcloud/keycloak-extension-demo/blob/main/docs/07-terms-guide.md)

### 관련 저장소

- [외부 User Storage REST API 구현체](https://github.com/cnapcloud/keycloak-user-storage)
- [React 인증 데모 앱](https://github.com/cnapcloud/react-keycloak-demo)
- [이니시스 간편인증 Mock 서버](https://github.com/cnapcloud/inicis-mockup-server)
