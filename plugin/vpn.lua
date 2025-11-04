local M = {}

local function get_vpn_status()
	local handle = io.popen("vpn-scripts -s")
	if not handle then
		return "unknown"
	end
	local result = handle:read("*a")
	handle:close()
	return result:match("^%s*(.-)%s*$") -- trim whitespace
end

local function toggle_vpn()
	local status = get_vpn_status()

	if status == "disconnected" or status == "unknown" then
		vim.fn.jobstart("vpn-scripts -c", {
			on_exit = function(_, exit_code)
				if exit_code == 0 then
					vim.notify("VPN Connected", vim.log.levels.INFO)
				else
					vim.notify("VPN Connection Failed", vim.log.levels.ERROR)
				end
			end,
		})
	elseif status == "connected" then
		vim.fn.jobstart("vpn-scripts -x", {
			on_exit = function(_, exit_code)
				if exit_code == 0 then
					vim.notify("VPN Disconnected", vim.log.levels.INFO)
				else
					vim.notify("VPN Disconnection Failed", vim.log.levels.ERROR)
				end
			end,
		})
	else
		vim.notify("Cannot determine VPN status", vim.log.levels.WARN)
	end
end

local function show_vpn_status()
	local status = get_vpn_status()
	local status_msg = "VPN Status: " .. status
	local level = status == "connected" and vim.log.levels.INFO
		or status == "disconnected" and vim.log.levels.WARN
		or vim.log.levels.ERROR
	vim.notify(status_msg, level)
end

-- Create user commands
vim.api.nvim_create_user_command("VPNToggle", toggle_vpn, {})
vim.api.nvim_create_user_command("VPNStatus", show_vpn_status, {})

-- Create keymaps
vim.keymap.set("n", "<leader>vc", toggle_vpn, { desc = "Toggle VPN connection" })
vim.keymap.set("n", "<leader>vs", show_vpn_status, { desc = "Show VPN status" })

return M
