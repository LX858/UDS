import { NumberInput, rem } from "@mantine/core";

const CallsignSelect = ({
  value,
  onChange,
  max,
}: {
  value: number;
  onChange: (value: number) => void;
  max: number;
}) => {
  return (
    <NumberInput
      value={value}
      w={rem(46)}
      hideControls
      onChange={(value) => {
        if (typeof value === "number") {
          onChange(value);
        }
      }}
      min={-1}
      max={max}
      styles={{
        input: {
          textAlign: "center",
        },
      }}
    />
  );
};

export default CallsignSelect;
