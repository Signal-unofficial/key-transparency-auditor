ARG JDK_VERSION=eclipse-temurin@sha256:24a8854594eea72c16822953e6cb96c78d10fc3c77b7b8a60ce8e5ac440a2337

# Generates auditor public/private key pair
FROM ${JDK_VERSION} AS gen-auditor-keys

WORKDIR /app/
COPY --link [ "./docker/gen_auditor_keys.sh", "./" ]

ENTRYPOINT [ "/app/gen_auditor_keys.sh" ]

# Copying legal notices, for final build stages
FROM scratch AS notices

WORKDIR /app/
COPY [ "./README.md", "./LICENSE", "./NOTICE.md", "./" ]

# Used to assert that licensing info is indeed copied
ENTRYPOINT [ "ls" ]

# Installing dependencies
FROM ${JDK_VERSION} AS dependencies

WORKDIR /app/
COPY --link --from=notices [ "/app/", "./" ]
COPY [ "./mvnw", "./mvnw" ]
COPY [ "./.mvn/", "./.mvn/" ]
COPY [ "./pom.xml", "./pom.xml" ]

RUN [ "./mvnw", "dependency:go-offline", "-U", "-q" ]

# Building and testing project
FROM ${JDK_VERSION} AS build-auditor

WORKDIR /app/
COPY --from=dependencies [ "/root/.m2/", "/root/.m2/" ]
COPY --from=dependencies [ "/app/", "./" ]
COPY [ "./src/", "./src/" ]

RUN [ "./mvnw", "install", "-am", "-q" ]

# Running project
FROM ${JDK_VERSION} AS run-auditor

ARG AUDITOR_VERSION=0.1

WORKDIR /app/
COPY --from=build-auditor [ "/app/target/key-transparency-auditor-${AUDITOR_VERSION}.jar", "./" ]

ENTRYPOINT [ "java", "-jar", "/app/key-transparency-auditor-${AUDITOR_VERSION}.jar" ]
