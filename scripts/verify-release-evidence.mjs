import fs from 'node:fs';

const file = process.argv[2];
if (!file) {
  console.error('用法: node scripts/verify-release-evidence.mjs evidence.json');
  process.exit(2);
}

const evidence = JSON.parse(fs.readFileSync(file, 'utf8'));
const required = [
  'install',
  'package_center',
  'start_stop_restart',
  'boot_autostart',
  'upgrade_preserves_data',
  'device_authorization',
  'chatgpt_connection',
  'mcp_discovery_and_calls',
  'system_information',
  'shell_and_processes',
  'scoped_file_read_write',
  'upload_download',
  'log_management',
  'windows_offline_nas_online',
];

const missing = required.filter((key) => evidence.acceptance?.[key] !== true);
if (evidence.target !== 'DS3615xs-j / DSM 6.2.3-25426 / bromolow' || missing.length) {
  console.error(`正式发布被阻止。目标 NAS 实测项未完整通过：${missing.join(', ') || 'target mismatch'}`);
  process.exit(1);
}
console.log('验收记录目标与必需项目均已通过。');

