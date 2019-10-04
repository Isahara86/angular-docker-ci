# Stage 0, "build-stage", based on Node.js, to build and compile Angular
FROM tiangolo/node-frontend:10 as build-stage

WORKDIR /app

COPY package*.json /app/

RUN npm install

COPY ./ /app/

RUN npm run test -- --browsers ChromeHeadlessNoSandbox --watch=false

ARG configuration=production

RUN npm run build -- --output-path=./dist/out --configuration $configuration

# Stahge 1, based on Nginx, to have only the compiled app, ready for production with Nginx
FROM nginx:1.15

COPY --from=build-stage /app/dist/out /usr/share/nginx/html

COPY ci/nginx-custom.conf /etc/nginx/conf.d/default.conf

ADD ci/run.sh .

ENTRYPOINT ["sh", "run.sh"]

# docker run -p 80:80 --env-file=./ci/.prod.env angular-docker-ci -d
