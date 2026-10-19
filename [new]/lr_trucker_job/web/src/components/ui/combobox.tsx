import * as React from 'react';
import {Combobox as BaseCombobox} from '@base-ui/react/combobox';
import {Check, ChevronDown, X} from 'lucide-react';

import {cn} from '@/lib/utils';

const Combobox = BaseCombobox.Root;

function useComboboxAnchor() {
  return React.useRef<HTMLDivElement>(null);
}

type ComboboxInputProps = Omit<
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Input>,
  'children'
> & {
  children?: React.ReactNode;
  inputClassName?: string;
  showClear?: boolean;
  showTrigger?: boolean;
};

const ComboboxInput = React.forwardRef<HTMLInputElement, ComboboxInputProps>(
  (
    {
      children,
      className,
      inputClassName,
      showClear = false,
      showTrigger = true,
      ...props
    },
    ref
  ) => (
    <div
      className={cn(
        'group/combobox flex h-9 w-full items-center gap-2 rounded-md border border-input bg-background px-3 text-sm shadow-sm ring-offset-background transition-colors focus-within:ring-1 focus-within:ring-ring aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40',
        props.disabled && 'cursor-not-allowed opacity-50',
        className
      )}
    >
      {children}
      <BaseCombobox.Input
        ref={ref}
        className={cn(
          'flex h-full w-full min-w-0 bg-transparent py-2 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed',
          inputClassName
        )}
        {...props}
      />
      {showClear ? (
        <BaseCombobox.Clear className="flex size-7 items-center justify-center rounded-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground">
          <X className="size-4" />
        </BaseCombobox.Clear>
      ) : null}
      {showTrigger ? (
        <BaseCombobox.Trigger className="flex size-7 items-center justify-center rounded-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground">
          <ChevronDown className="size-4" />
        </BaseCombobox.Trigger>
      ) : null}
    </div>
  )
);
ComboboxInput.displayName = 'ComboboxInput';

type ComboboxContentProps = React.ComponentPropsWithoutRef<
  typeof BaseCombobox.Positioner
> & {
  children?: React.ReactNode;
};

const ComboboxContent = React.forwardRef<HTMLDivElement, ComboboxContentProps>(
  ({className, children, sideOffset = 4, ...props}, ref) => (
    <BaseCombobox.Portal>
      <BaseCombobox.Positioner sideOffset={sideOffset} {...props}>
        <BaseCombobox.Popup
          ref={ref}
          className={cn(
            'z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover text-popover-foreground shadow-md',
            className
          )}
        >
          {children}
        </BaseCombobox.Popup>
      </BaseCombobox.Positioner>
    </BaseCombobox.Portal>
  )
);
ComboboxContent.displayName = 'ComboboxContent';

const ComboboxList = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.List>
>(({className, children, ...props}, ref) => (
  <BaseCombobox.List
    ref={ref}
    className={cn('max-h-72 overflow-y-auto p-1', className)}
    {...props}
  >
    {children}
  </BaseCombobox.List>
));
ComboboxList.displayName = 'ComboboxList';

const ComboboxEmpty = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Empty>
>(({className, ...props}, ref) => (
  <BaseCombobox.Empty
    ref={ref}
    className={cn('px-3 py-2 text-sm text-muted-foreground', className)}
    {...props}
  />
));
ComboboxEmpty.displayName = 'ComboboxEmpty';

const ComboboxGroup = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Group>
>(({className, ...props}, ref) => (
  <BaseCombobox.Group
    ref={ref}
    className={cn('overflow-hidden p-1', className)}
    {...props}
  />
));
ComboboxGroup.displayName = 'ComboboxGroup';

const ComboboxLabel = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.GroupLabel>
>(({className, ...props}, ref) => (
  <BaseCombobox.GroupLabel
    ref={ref}
    className={cn(
      'px-2 py-1.5 text-xs font-medium text-muted-foreground',
      className
    )}
    {...props}
  />
));
ComboboxLabel.displayName = 'ComboboxLabel';

const ComboboxCollection = BaseCombobox.Collection;

const ComboboxItem = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Item>
>(({className, children, ...props}, ref) => (
  <BaseCombobox.Item
    ref={ref}
    className={cn(
      'relative flex w-full cursor-default items-center rounded-sm py-1.5 pl-2 pr-8 text-sm outline-none transition-colors data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground',
      className
    )}
    {...props}
  >
    <BaseCombobox.ItemIndicator className="absolute right-2 flex size-4 items-center justify-center">
      <Check className="size-4" />
    </BaseCombobox.ItemIndicator>
    {children}
  </BaseCombobox.Item>
));
ComboboxItem.displayName = 'ComboboxItem';

const ComboboxSeparator = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({className, ...props}, ref) => (
  <div
    ref={ref}
    className={cn('-mx-1 my-1 h-px bg-border', className)}
    role="separator"
    {...props}
  />
));
ComboboxSeparator.displayName = 'ComboboxSeparator';

const ComboboxTrigger = React.forwardRef<
  HTMLButtonElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Trigger>
>(({className, children, ...props}, ref) => (
  <BaseCombobox.Trigger
    ref={ref}
    className={cn(
      'flex h-9 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm ring-offset-background transition-colors outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50',
      className
    )}
    {...props}
  >
    {children}
    <ChevronDown className="size-4 text-muted-foreground" />
  </BaseCombobox.Trigger>
));
ComboboxTrigger.displayName = 'ComboboxTrigger';

const ComboboxValue = BaseCombobox.Value;

const ComboboxChips = React.forwardRef<
  HTMLDivElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Chips>
>(({className, ...props}, ref) => (
  <BaseCombobox.Chips
    ref={ref}
    className={cn(
      'flex min-h-9 w-full flex-wrap items-center gap-1 rounded-md border border-input bg-background px-2 py-1 shadow-sm ring-offset-background transition-colors focus-within:ring-1 focus-within:ring-ring',
      className
    )}
    {...props}
  />
));
ComboboxChips.displayName = 'ComboboxChips';

type ComboboxChipProps = React.ComponentPropsWithoutRef<
  typeof BaseCombobox.Chip
> & {
  showRemove?: boolean;
};

const ComboboxChip = React.forwardRef<HTMLDivElement, ComboboxChipProps>(
  ({className, children, showRemove = true, ...props}, ref) => (
    <BaseCombobox.Chip
      ref={ref}
      className={cn(
        'inline-flex items-center gap-1 rounded-sm bg-secondary px-2 py-1 text-xs text-secondary-foreground',
        className
      )}
      {...props}
    >
      <span className="truncate">{children}</span>
      {showRemove ? (
        <BaseCombobox.ChipRemove className="rounded-sm text-muted-foreground transition-colors hover:text-foreground">
          <X className="size-3" />
        </BaseCombobox.ChipRemove>
      ) : null}
    </BaseCombobox.Chip>
  )
);
ComboboxChip.displayName = 'ComboboxChip';

const ComboboxChipsInput = React.forwardRef<
  HTMLInputElement,
  React.ComponentPropsWithoutRef<typeof BaseCombobox.Input>
>(({className, ...props}, ref) => (
  <BaseCombobox.Input
    ref={ref}
    className={cn(
      'h-7 min-w-[7rem] flex-1 bg-transparent px-1 text-sm outline-none placeholder:text-muted-foreground',
      className
    )}
    {...props}
  />
));
ComboboxChipsInput.displayName = 'ComboboxChipsInput';

export {
  Combobox,
  ComboboxChip,
  ComboboxChips,
  ComboboxChipsInput,
  ComboboxCollection,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxGroup,
  ComboboxInput,
  ComboboxItem,
  ComboboxLabel,
  ComboboxList,
  ComboboxSeparator,
  ComboboxTrigger,
  ComboboxValue,
  useComboboxAnchor,
};
