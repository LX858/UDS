import { AppActions, AppDispatch } from '../store';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { useDispatch } from 'react-redux';

interface Props {
  action: keyof typeof AppActions;
}

function AppActionHook(props: Props) {
  const dispatch = useDispatch<AppDispatch>();
  useNuiEvent(props.action, (data) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const a = AppActions[props.action] as any;
    dispatch(a(data));
  });

  return null;
}

export default AppActionHook;
