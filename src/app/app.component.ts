import { Component, Inject } from '@angular/core';
import { environment } from '../environments/environment';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  title = 'angular-docker-ci';
  mode = 'Production:' + environment.production;

  constructor(@Inject('BACKEND_API_URL') public apiUrl: string) {

  }
}
