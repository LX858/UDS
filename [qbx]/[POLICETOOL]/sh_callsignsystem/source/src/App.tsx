import { useMemo, useState } from "react";
import { emitNet, onNet } from "./hooks";
import {
  ActionIcon,
  Button,
  Group,
  Paper,
  rem,
  Stack,
  Text,
  Title,
  Tooltip,
  Transition,
} from "@mantine/core";
import { useDisclosure, useWindowEvent } from "@mantine/hooks";
import { IconHistoryToggle, IconX } from "@tabler/icons-react";
import CallsignSelect from "./components/CallsignSelect";

interface ExamplePayload {
  vehicleType: "oldGen" | "newGen";
  locales: {
    revertChanges: string;
    title: string;
    frontCallsigns: string;
    backCallsigns: string;
    save: string;
    close: string;
  };
  currentCallsigns: {
    front: {
      ["8"]: number;
      ["10"]: number;
      ["9"]: number;
    };
    frontCount: {
      ["8"]: number;
      ["10"]: number;
      ["9"]: number;
    };
    back: {
      ["38"]: number;
      ["25"]: number;
    };
    backCount: {
      ["38"]: number;
      ["25"]: number;
    };
  };
}

const App = () => {
  const [opened, handlers] = useDisclosure(false);

  const handlerClose = () => {
    handlers.close();
    emitNet("closeMenu");
  };

  useWindowEvent("keydown", (event) => {
    if (event.key === "Escape") handlerClose();
  });

  const [locales, setLocales] = useState<ExamplePayload["locales"]>({
    revertChanges: "",
    title: "",
    frontCallsigns: "",
    backCallsigns: "",
    save: "",
    close: "",
  });

  const [callsigns, setCallsigns] = useState<
    ExamplePayload["currentCallsigns"]
  >({
    front: {
      ["8"]: -1,
      ["10"]: -1,
      ["9"]: -1,
    },
    frontCount: {
      ["8"]: -1,
      ["10"]: -1,
      ["9"]: -1,
    },
    back: {
      ["38"]: -1,
      ["25"]: -1,
    },
    backCount: {
      ["38"]: -1,
      ["25"]: -1,
    },
  });

  const [vehicleType, setVehicleType] =
    useState<ExamplePayload["vehicleType"]>("oldGen");

  onNet<ExamplePayload>({
    eventName: "openMenu",
    handler: (payload) => {
      handlers.open();
      setCallsigns(payload.currentCallsigns);
      setLocales(payload.locales);
      setVehicleType(payload.vehicleType);
    },
  });

  const handlerChangeFront = useMemo(() => {
    return (index: string, value: number) => {
      setCallsigns((prev) => ({
        ...prev,
        front: {
          ...prev.front,
          [index]: value,
        },
      }));

      emitNet("updateCallsign", {
        payload: {
          index: parseInt(index),
          value,
        },
      });
    };
  }, []);

  const handlerChangeBack = useMemo(() => {
    return (index: string, value: number) => {
      setCallsigns((prev) => ({
        ...prev,
        back: {
          ...prev.back,
          [index]: value,
        },
      }));

      emitNet("updateCallsign", {
        payload: {
          index: parseInt(index),
          value,
        },
      });
    };
  }, []);

  const handlerRevert = () => {
    emitNet("revertCallsigns", {
      handler(payload: ExamplePayload["currentCallsigns"]) {
        setCallsigns(payload);
      },
    });
  };

  const handlerSave = () => {
    emitNet("saveCallsigns");
    handlers.close();
  };

  return (
    <Transition
      mounted={opened}
      transition="fade-left"
      duration={400}
      timingFunction="ease"
    >
      {(styles) => (
        <Stack
          style={styles}
          h="100vh"
          justify="center"
          align="end"
          p={rem(16)}
        >
          <Paper p={rem(8)} miw={rem(240)}>
            <Stack>
              <Group justify="space-between">
                <Title order={4} lineClamp={1}>
                  {locales.title}
                </Title>

                <Group gap={rem(4)}>
                  <Tooltip label={locales.revertChanges}>
                    <ActionIcon
                      size="sm"
                      variant="light"
                      onClick={handlerRevert}
                    >
                      <IconHistoryToggle />
                    </ActionIcon>
                  </Tooltip>

                  <ActionIcon size="sm" variant="light" onClick={handlerClose}>
                    <IconX />
                  </ActionIcon>
                </Group>
              </Group>

              <div>
                <Text fw={500} ta="center" c="dimmed" fz="sm" mb={rem(4)}>
                  {locales.frontCallsigns}
                </Text>
                <Group justify="center">
                  <CallsignSelect
                    value={callsigns.front["8"]}
                    onChange={(value) => handlerChangeFront("8", value)}
                    max={callsigns.frontCount["8"]}
                  />
                  <CallsignSelect
                    value={callsigns.front[vehicleType === "newGen" ? "10" : "9"]}
                    onChange={(value) => handlerChangeFront(vehicleType === "newGen" ? "10" : "9", value)}
                    max={callsigns.frontCount[vehicleType === "newGen" ? "10" : "9"]}
                  />
                  <CallsignSelect
                    value={callsigns.front[vehicleType === "newGen" ? "9" : "10"]}
                    onChange={(value) => handlerChangeFront(vehicleType === "newGen" ? "9" : "10", value)}
                    max={callsigns.frontCount[vehicleType === "newGen" ? "9" : "10"]}
                  />
                </Group>
              </div>

              {Object.keys(callsigns.back).length > 0 && (
                <div>
                  <Text fw={500} ta="center" c="dimmed" fz="sm" mb={rem(4)}>
                    {locales.backCallsigns}
                  </Text>
                  <Group justify="center">
                    <CallsignSelect
                      value={callsigns.back["38"]}
                      onChange={(value) => handlerChangeBack("38", value)}
                      max={callsigns.backCount["38"]}
                    />
                    <CallsignSelect
                      value={callsigns.back["25"]}
                      onChange={(value) => handlerChangeBack("25", value)}
                      max={callsigns.backCount["25"]}
                    />
                  </Group>
                </div>
              )}

              <Group justify="end" gap={rem(4)}>
                <Button size="xs" variant="light" onClick={handlerSave}>
                  {locales.save}
                </Button>

                <Button size="xs" variant="light" onClick={handlerClose}>
                  {locales.close}
                </Button>
              </Group>
            </Stack>
          </Paper>
        </Stack>
      )}
    </Transition>
  );
};

export default App;
