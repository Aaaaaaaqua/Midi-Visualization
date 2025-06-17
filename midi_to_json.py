# midi_to_json.py
import mido
import json

mid = mido.MidiFile("example.mid")
notes = []
active_notes = {}  # 跟踪正在播放的音符 {(channel, note): {"time": start_time, "velocity": velocity}}

time = 0
for msg in mid:
    time += msg.time
    
    if msg.type == 'note_on' and msg.velocity > 0:
        # 音符开始
        note_key = (msg.channel, msg.note)
        active_notes[note_key] = {
            "time": time,
            "velocity": msg.velocity
        }
    
    elif (msg.type == 'note_off') or (msg.type == 'note_on' and msg.velocity == 0):
        # 音符结束（note_off 或 velocity=0 的 note_on）
        note_key = (msg.channel, msg.note)
        if note_key in active_notes:
            start_data = active_notes[note_key]
            duration = time - start_data["time"]
            
            notes.append({
                "time": start_data["time"],
                "note": msg.note,
                "velocity": start_data["velocity"],
                "duration": duration
            })
            
            del active_notes[note_key]

# 处理任何未结束的音符（给它们一个默认时值）
for note_key, start_data in active_notes.items():
    channel, note_value = note_key
    notes.append({
        "time": start_data["time"],
        "note": note_value,
        "velocity": start_data["velocity"],
        "duration": 0.5  # 默认时值0.5秒
    })

# # Iterate through tracks to extract and print track names
# for i, track in enumerate(mid.tracks):
#     for msg in track:
#             print(f"Track {i} - Name: {msg.name}")
#             print(f"Track {i} name: {msg.name}")
#             # Example: Store track names in a list for further use
#             track_names = []
#             track_names.append({"track_index": i, "track_name": msg.name})
#             print(f"Track names collected: {track_names}")
# 按时间排序
notes.sort(key=lambda x: x["time"])

with open("notes.json", "w") as f:
    json.dump(notes, f, indent=2)
print(f"MIDI notes extracted and saved to notes.json ({len(notes)} notes with duration)")
print("Sample note:", notes[0] if notes else "No notes found")