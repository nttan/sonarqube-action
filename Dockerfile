FROM newtmitch/sonar-scanner:4.0.0-alpine

LABEL "com.github.actions.name"="SonarQube Scan"
LABEL "com.github.actions.description"="Scan your code with SonarQube Scanner to detect bugs, vulnerabilities and code smells in more than 25 programming languages."
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="green"

LABEL version="0.0.1"
LABEL repository="https://github.com/kitabisa/sonarqube-action"
LABEL homepage="https://kitabisa.github.io"
LABEL maintainer="dwisiswant0"

RUN npm config set unsafe-perm true && \
  npm install --silent --save-dev -g typescript@3.5.2 && \
  npm config set unsafe-perm false
ENV NODE_PATH "/usr/lib/node_modules/"

COPY entrypoint.sh /entrypoint.sh
COPY check.sh /check.sh
COPY common.sh /common.sh
COPY readproperties.awk /readproperties.awk
RUN chmod +x /entrypoint.sh
RUN chmod +x /check.sh
RUN chmod +x /common.sh

ENTRYPOINT ["/entrypoint.sh"]
