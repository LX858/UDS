import type {TruckerSnapshot} from '@/generated/contracts';

export type {TruckerSnapshot};

export type Localize = (
  key: string,
  args?: Record<string, string | number>
) => string;

export type VehicleSelection =
  {mode: 'rental'; key: 'mule' | 'benson' | 'pounder' | 'hauler' | 'packer' | 'phantom'};

export const missionSteps = [
  'step_1',
  'step_2',
  'step_3',
  'step_4',
  'step_5',
  'step_6',
  'step_7',
] as const;

export function formatMoney(value: number) {
  return `$${new Intl.NumberFormat('vi-VN').format(value)}`;
}

export function formatConversion(line: {
  quantity: number; label: string; destinationAmount: number;
  destinationLabel: string; destinationUnit: 'item' | 'liter';
}) {
  return `${line.quantity} ${line.label} → ${line.destinationAmount} ${line.destinationUnit === 'liter' ? 'lít ' : ''}${line.destinationLabel}`;
}
