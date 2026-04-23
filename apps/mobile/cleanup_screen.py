import sys

filepath = r'd:\Block-Puzzle\apps\mobile\lib\features\game_loop\presentation\game_loop_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Original: {len(lines)} lines')

# Keep: 1-679 (idx 0-678), 918-1591 (idx 917-1590), 1789-end (idx 1788+)
keep = lines[0:679] + ['\n'] + lines[917:1591] + ['\n'] + lines[1788:]

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(keep)

print(f'Clean: {len(keep)} lines')
print('Done!')
