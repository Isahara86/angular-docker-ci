import { Inject, Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class EnvService {
  constructor(
    @Inject('BACKEND_API_URL') public apiUrl: string,
    @Inject('DEFAULT_LANGUAGE') public defaultLanguage: string
  ) {}
}
