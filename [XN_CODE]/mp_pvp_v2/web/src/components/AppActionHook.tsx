import { AppActions } from '../store';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { useDispatch } from 'react-redux';
import { Box, Text } from 'lr-components';
import { isEnvBrowser } from '../utils/misc';
import type { AppDispatch } from '@/store';

interface Props {
  action: keyof typeof AppActions;
}

function AppActionHook(props: Props) {
  const dispatch = useDispatch<AppDispatch>();
  const isDev = isEnvBrowser();
  useNuiEvent(props.action, (data) => {
    const a = AppActions[props.action] as any;
    dispatch(a(data));
  });

  return (
    isDev && (
      <Box
        rPadding={5}
        backgroundColor='#1f1f1f'
        rBorderRadius={10}
        opacity={0.3}
      >
        <Text color='white'>{props.action}</Text>
      </Box>
    )
  );
}

export default AppActionHook;
