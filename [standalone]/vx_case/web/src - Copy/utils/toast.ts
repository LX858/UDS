import {toast, ToastOptions} from 'react-toastify';

const options: ToastOptions = {
  position: 'top-right',
  autoClose: 5000,
  hideProgressBar: false,
  closeOnClick: true,
  theme: 'dark',
};

export function showNotify(title: string, message: string) {
  toast.info(`${title}: ${message}`, options);
}
