
# Home Assistant battery reporting

This optional integration reports the Kindle battery level
to Home Assistant whenever the dashboard image is refreshed.

No MQTT broker, additional packages or containers are required.

## Requirements

- Kindle Dash with the bundled xh HTTP client
- Home Assistant
- A Home Assistant number helper
- A webhook automation

## 1. Create a Home Assistant helper

Create a Number helper with:

- Name: Kindle Battery
- Entity ID: `input_number.kindle_battery`
- Minimum: 0
- Maximum: 100
- Step: 1
- Unit: %

## 2. Create a webhook automation

Use the following YAML in Home Assistant:

```yaml
alias: Kindle Battery Webhook

triggers:
  - trigger: webhook
    webhook_id: REPLACE_WITH_RANDOM_SECRET
    allowed_methods:
      - POST
    local_only: true

conditions:
  - condition: template
    value_template: >
      {{ trigger.json is defined
         and trigger.json.battery is defined
         and is_number(trigger.json.battery)
         and 0 <= (trigger.json.battery | float) <= 100 }}

actions:
  - action: input_number.set_value
    target:
      entity_id: input_number.kindle_battery
    data:
      value: "{{ trigger.json.battery | int }}"

mode: single
```

Use a long, random webhook ID.

If Home Assistant is behind a reverse proxy, ensure
that the webhook is reachable and that `local_only`
matches your network setup.

## 3. Configure Kindle6 Dash Battery

Prefer creating `/mnt/us/dashboard/local/env.private.sh` from `env.private.example.sh` on the Kindle. It is loaded by `local/env.sh` and must not be committed.

Set:

```sh
export DASHBOARD_URL="https://your-server.example/dashboard.png"

export BATTERY_WEBHOOK_URL="http://HOME_ASSISTANT_IP:8123/api/webhook/YOUR_SECRET"
```

Do not commit your actual webhook URL.

## 4. Test without suspend

Connect to the Kindle using SSH:

```sh
cd /mnt/us/dashboard
. ./local/env.sh
sh ./local/fetch-dashboard.sh /mnt/us/dashboard/test.png
```

This tests the dashboard download and battery reporting
without starting the suspend loop.

## 5. Check logging

When launched normally, Kindle6 Dash Battery continuously rotates logs in:

```text
/mnt/us/dashboard/logs/dash.log
```

Example output:

```text
Dashboard: PNG downloaded
Battery: Sending 85%
Battery: Webhook sent (85%)
```

The webhook is executed before the Kindle enters suspend.

## Troubleshooting

### xh reports mixed request body and data

Ensure the HTTP commands use `--ignore-stdin`.

This is necessary for background launcher compatibility.

### Battery helper does not update

Check:

1. The Home Assistant automation trace.
2. The configured webhook URL.
3. `logs/dash.log`.
4. Whether `env.sh` exports `BATTERY_WEBHOOK_URL`.

### Manual test works but the launcher does not

Check that both the image download and webhook POST
use `--ignore-stdin`.

## Security

A Home Assistant webhook ID is a secret.
Do not publish real webhook IDs, passwords, tokens
or private configuration files.

Prefer access through a trusted local network.
```
