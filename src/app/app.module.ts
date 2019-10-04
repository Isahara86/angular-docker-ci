import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { environment } from '../environments/environment';

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
export class AppModule { }
