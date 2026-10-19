import * as React from 'react';
import {cva, type VariantProps} from 'class-variance-authority';
import {ChevronDown} from 'lucide-react';

import {cn} from '@/lib/utils';

const nativeSelectVariants = cva(
  'flex w-full appearance-none rounded-md border border-input bg-background shadow-sm transition-colors outline-none ring-offset-background focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40',
  {
    variants: {
      size: {
        default: 'h-9 px-3 py-2 text-sm',
        sm: 'h-8 px-3 py-1.5 text-sm',
      },
    },
    defaultVariants: {
      size: 'default',
    },
  }
);

type NativeSelectProps = Omit<
  React.SelectHTMLAttributes<HTMLSelectElement>,
  'size'
> &
  VariantProps<typeof nativeSelectVariants>;

const NativeSelect = React.forwardRef<HTMLSelectElement, NativeSelectProps>(
  ({className, size, children, ...props}, ref) => (
    <div className="relative w-full">
      <select
        ref={ref}
        className={cn(nativeSelectVariants({size}), 'pe-9', className)}
        {...props}
      >
        {children}
      </select>
      <ChevronDown className="pointer-events-none absolute right-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
    </div>
  )
);
NativeSelect.displayName = 'NativeSelect';

const NativeSelectOption = React.forwardRef<
  HTMLOptionElement,
  React.OptionHTMLAttributes<HTMLOptionElement>
>(({children, ...props}, ref) => (
  <option ref={ref} {...props}>
    {children}
  </option>
));
NativeSelectOption.displayName = 'NativeSelectOption';

const NativeSelectOptGroup = React.forwardRef<
  HTMLOptGroupElement,
  React.OptgroupHTMLAttributes<HTMLOptGroupElement>
>(({children, ...props}, ref) => (
  <optgroup ref={ref} {...props}>
    {children}
  </optgroup>
));
NativeSelectOptGroup.displayName = 'NativeSelectOptGroup';

export {NativeSelect, NativeSelectOptGroup, NativeSelectOption};
