# AngularDockerCi

## Intro
When you work with angular there are several stages witch project should pass.
 1. Build
 2. Unit test
 3. Deploy to stage server
 4. QA test
 5. Deploy to production server
 
When you work with long time project it's obvious to use CI-server to build test and deploy your code.
So I'm as a developer strive to:
 1. Run tests with every task
 2. Prevent deployment if tests failed
 3. Deploy to prod the same code as on stage server
 4. Encapsulate all my build stage to prevent DevOps break code building.
 
 Let's discuss each statement:
 
 "1.2."   " Run tests with every task" 
  It would be wonderful to know all errors before QA. It's not a problem for QA find a bug but it causes a chain of events: QA check my task -> QA find a bug -> QA Create a bug report -> Me get acquires with bug report -> Me find and fix a bug. -> QA test fixed code. The chain could take a lot of time so fun test before QA could help a lot. I don't wont wasting everyone's time.
  
 "3." Deploy to prod the same code as on stage server. If you build your code several times one by one in most cases you will get the same result. IN MOST CASES... There are always a chance of error. If library on package json has no fixed version 
 ```json
"dependencies": {
    "@angular/animations": "~8.2.0",
    "@angular/common": "~8.2.0",
    "@angular/compiler": "~8.2.0",
}

 ```
todays buils does not equal last week build just because
 
 last week `"@angular/animations": "~8.2.0",`  === `"@angular/animations": "8.2.1",`
 but today new version appears `"@angular/animations": "~8.2.0",`  === `"@angular/animations": "8.2.2",`
 
 This small difference could cause a bug difference - your last week's build IS NOT EQUAL today's build even if your code hasn't changed.
 
 "4." Encapsulate all my build stage to prevent DevOps break code building. 
  I don't wont to expose all build and test details to DevOps. It's much easier to be independent from server environment when I need to change node.js version of some other stuff. 
  
  
So we have a lot of questions let's try to find the way to solve them step by step.

 Step one
 Build a project in Docker image. - it will help to encapsulate build process.
 Step two 
 Test code during Docker image building - it will prevent to create image without pass all tests.
 Step three
 Adjust angular and docker to get environment variables when docker container starting - So we could use the same build for production and stage server.
 
## Angular CI code step by step

### Step one 
Create Docker file

```Docker
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
```

If we are going to test angular during Docker build we will require Chrome Headless

First, you need to add Puppeteer as a dependency following Karma’s official documentation:
Go to your application directory and install Puppeteer:
```
npm install puppeteer --save-dev
```
Then install karma-chrome-launcher:
```
npm install karma-chrome-launcher --save-dev
```
Modify your src/karma.conf.js file, add this on the top:
```
process.env.CHROME_BIN = require('puppeteer').executablePath()
```
Modify your src/karma.conf.js file, there's a line with:
``` javascript
browsers: ['Chrome'],
```
replace that line with:
``` javascript
browsers: ['Chrome', 'ChromeHeadlessNoSandbox'],
    captureTimeout: 210000,
    browserDisconnectTolerance: 3,
    browserDisconnectTimeout: 210000,
    browserNoActivityTimeout: 210000,
    customLaunchers: {
      ChromeHeadlessNoSandbox: {
        base: 'ChromeHeadless',
        flags: [
          '--no-sandbox',
          // Without a remote debugging port, Google Chrome exits immediately.
          '--remote-debugging-port=9222',
        ]
      }
    },
```
    
your final src/karma.conf.js might look like:

``` javascript
// Karma configuration file, see link for more information
// https://karma-runner.github.io/1.0/config/configuration-file.html
process.env.CHROME_BIN = require('puppeteer').executablePath()
module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage-istanbul-reporter'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    client: {
      clearContext: false // leave Jasmine Spec Runner output visible in browser
    },
    coverageIstanbulReporter: {
      dir: require('path').join(__dirname, '../coverage'),
      reports: ['html', 'lcovonly'],
      fixWebpackSourcePaths: true
    },
    reporters: ['progress', 'kjhtml'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['Chrome', 'ChromeHeadlessNoSandbox'],
    captureTimeout: 210000,
    browserDisconnectTolerance: 3,
    browserDisconnectTimeout: 210000,
    browserNoActivityTimeout: 210000,
    customLaunchers: {
      ChromeHeadlessNoSandbox: {
        base: 'ChromeHeadless',
        flags: [
          '--no-sandbox',
          // Without a remote debugging port, Google Chrome exits immediately.
          '--remote-debugging-port=9222',
        ]
      }
    },
    singleRun: false
  });
};
```

Run a single (not “watch”) test locally, in headless mode(Dockerfile):
```
ng test --browsers ChromeHeadlessNoSandbox --watch=false
```

### Step two

Add run.sh to `/ci/run.sh`

```shell script
for i in /usr/share/nginx/html/main*.js; do
    [ -f "$i" ] || break
    mainFileName="$i"
    envsubst '$BACKEND_API_URL $DEFAULT_LANGUAGE ' <${mainFileName} >main.tmp
    mv main.tmp ${mainFileName}
done
nginx -g 'daemon off;'
```

this script will change angular-environment-variables according to Docker environment variables.

### Step three

Add `/ci/.prod.env`

```.env
BACKEND_API_URL=my_prod_backend
DEFAULT_LANGUAGE=production_language
```

Add `/ci/.stage.env`

```.env
BACKEND_API_URL=my_stage_backend
DEFAULT_LANGUAGE=stage_language
```

### Step four

Modify `environment.prod.ts`

before
```typescript
export const environment = {
  production: true
};
```

after
```typescript
export const environment = {
  production: true,
  backendApiUrl: '${BACKEND_API_URL}',
  defaultLanguage: '${DEFAULT_LANGUAGE}'
};
```

### Step five

Modify `app.module.ts`

```typescript
@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [
    {provide: 'BACKEND_API_URL', useValue: environment.backendApiUrl},
    {provide: 'DEFAULT_LANGUAGE', useValue: environment.defaultLanguage}
  ],
  bootstrap: [AppComponent]
})
```

Now everywhere you need to use environment DON'T import 
```typescript
import { environment } from '../environments/environment';
```

But INJECT
```typescript
export class AppComponent {
  constructor(@Inject('BACKEND_API_URL') public apiUrl: string) {}
}
```

Or to improve developer experience you can create `env.service.ts`

```typescript
@Injectable({
  providedIn: 'root'
})
export class EnvService {
  constructor(
    @Inject('BACKEND_API_URL') public apiUrl: string,
    @Inject('DEFAULT_LANGUAGE') public defaultLanguage: string
  ) {}
}
```


## Conclusions: 
From now your DevOps will be happy. Everything he have to be concerned it's Docker and right environment variables.
You are safe - NO project rebuild during deployment and NO DevOps intrusion into build process.

Related articles:
 1. https://medium.com/@tiangolo/angular-in-docker-with-nginx-supporting-environments-built-with-multi-stage-docker-builds-bb9f1724e984
 2. https://blog.codecentric.de/en/2019/03/docker-angular-dockerize-app-easily/
