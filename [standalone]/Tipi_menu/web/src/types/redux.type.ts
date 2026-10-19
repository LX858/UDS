import { Dispatch } from '@reduxjs/toolkit';
import { RootState } from '../store';

export type AsyncThunkConfig = {
  state: RootState;
  dispatch: Dispatch;
  extra?: unknown;
  rejectValue?: unknown;
  serializedErrorType?: unknown;
  pendingMeta?: unknown;
  fulfilledMeta?: unknown;
  rejectedMeta?: unknown;
};

export type IResponseSuccess<T = unknown> = {
  status: 'success';
  data: T;
  message?: string;
};

export type IResponseError = {
  status: 'error';
  message: string;
};

export type IResponse<T = unknown> = IResponseSuccess<T> | IResponseError;
