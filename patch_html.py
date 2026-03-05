"""
chinitsu_trainer HTMLに3つの新機能をパッチ適用するスクリプト
1. 問題DB拡充（200問以上）
2. 問題解説（手牌分解表示）
3. お気に入り・苦手問題機能
"""
import pathlib
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

src = pathlib.Path(r"C:\Users\haman\Downloads\チンイツ") / "chinitsu_trainer (1).html"
dst = pathlib.Path(r"C:\Users\haman\Downloads\チンイツ") / "chinitsu_trainer_v2.html"

html = src.read_text(encoding='utf-8')

# ── 1. 新しいDBを読み込み ──
db_file = pathlib.Path(r"C:\Users\haman\Downloads\チンイツ") / "db_output.txt"
new_db = db_file.read_text(encoding='utf-8').strip()

# 既存DBを置換
db_pattern = r'const DB = \[.*?\];'
html = re.sub(db_pattern, new_db, html, flags=re.DOTALL)

# ── 2. 追加CSS ──
additional_css = """
/* ── お気に入り・苦手問題 ── */
.fav-btn{position:absolute;top:-10px;right:12px;background:var(--paper2);border:none;cursor:pointer;font-size:18px;padding:0 6px;color:#ccc;z-index:10;line-height:1}
.fav-btn.active{color:var(--gold)}
.filter-modes{display:flex;gap:8px;flex-wrap:wrap;justify-content:center;width:100%;max-width:440px}
.fm{padding:10px 16px;font-family:'Noto Serif JP',serif;font-size:12px;font-weight:700;letter-spacing:.08em;background:var(--paper2);border:1.5px solid var(--tile-b);border-radius:4px;cursor:pointer;transition:all .15s}
.fm:hover{background:var(--ink);color:var(--paper);border-color:var(--ink)}
.fm:disabled{opacity:.35;cursor:not-allowed}
.fm .cnt{font-size:10px;color:#6a5030;margin-left:4px}
.weak-notice{font-size:11px;color:#6a5030;margin-top:4px}

/* ── 手牌分解解説 ── */
.decomp-area{width:100%;margin-top:8px;display:none}
.decomp-area.show{display:block;animation:fi .2s ease}
.decomp-toggle{width:100%;max-width:320px;padding:8px;font-family:'Noto Serif JP',serif;font-size:12px;font-weight:700;letter-spacing:.1em;background:var(--paper2);border:1.5px solid var(--tile-b);color:var(--ink);border-radius:4px;cursor:pointer;margin-top:4px}
.decomp-toggle:hover{background:var(--paper3)}
.decomp-wait{margin-bottom:10px;padding:8px;background:var(--paper2);border:1px solid var(--tile-b);border-radius:4px}
.decomp-label{font-size:11px;font-weight:700;color:var(--green);margin-bottom:4px;letter-spacing:.1em}
.decomp-row{display:flex;align-items:center;gap:6px;flex-wrap:wrap;margin-bottom:4px}
.decomp-group{display:flex;align-items:center;gap:1px;padding:2px 4px;background:var(--paper3);border-radius:3px;position:relative}
.decomp-group-label{font-size:8px;color:#6a5030;position:absolute;top:-10px;left:2px;white-space:nowrap}
.decomp-tile{width:22px;height:auto;border-radius:2px}
.decomp-plus{font-size:12px;color:#8a7040;font-weight:700}
"""

# </style>の前に追加
html = html.replace('</style>', additional_css + '\n</style>')

# ── 3. 追加HTML要素 ──

# スタート画面にフィルターボタンを追加（.modes の後に）
filter_html = """
  <div class="filter-modes" id="filterModes">
    <button class="fm" id="favBtn" onclick="startFiltered('fav')" disabled>★ お気に入り<span class="cnt" id="favCnt">(0)</span></button>
    <button class="fm" id="weakBtn" onclick="startFiltered('weak')" disabled>▼ 苦手問題<span class="cnt" id="weakCnt">(0)</span></button>
  </div>"""

html = html.replace(
    '</div>\n  <div class="rulebox">',
    '</div>\n' + filter_html + '\n  <div class="rulebox">'
)

# ゲーム画面に分解解説エリアとお気に入りボタンのHTML
# フィードバックの後に分解解説ボタンと分解エリアを追加
decomp_html = """
    <button class="decomp-toggle" id="decompToggle" style="display:none" onclick="toggleDecomp()">▼ 手牌の分解を見る</button>
    <div class="decomp-area" id="decompArea"></div>"""

html = html.replace(
    '<button class="bnx"',
    decomp_html + '\n    <button class="bnx"'
)

# ── 4. 追加JavaScript ──

additional_js = """
// ═══════════════════════════════════════
// お気に入り・苦手問題（localStorage）
// ═══════════════════════════════════════
function tileKey(tiles){ return JSON.stringify([...tiles].sort((a,b)=>a-b)); }

function loadSet(key){
  try{ const d=localStorage.getItem(key); return d?new Set(JSON.parse(d)):new Set(); }
  catch(e){ return new Set(); }
}
function saveSet(key, s){ localStorage.setItem(key, JSON.stringify([...s])); }

const favs = loadSet('chinitsu_favorites');
const weaks = loadSet('chinitsu_weak');

function updateFilterUI(){
  const favBtn=$('favBtn'), weakBtn=$('weakBtn');
  if(favBtn){ favBtn.disabled=favs.size===0; $('favCnt').textContent='('+favs.size+')'; }
  if(weakBtn){ weakBtn.disabled=weaks.size===0; $('weakCnt').textContent='('+weaks.size+')'; }
}

function toggleFavorite(){
  const tiles = G.probs[G.idx];
  const key = tileKey(tiles);
  if(favs.has(key)){
    favs.delete(key);
  } else {
    favs.add(key);
  }
  saveSet('chinitsu_favorites', favs);
  updateFavBtn();
  updateFilterUI();
}

function updateFavBtn(){
  const tiles = G.probs[G.idx];
  const key = tileKey(tiles);
  const btn = document.querySelector('.fav-btn');
  if(btn){
    btn.className = 'fav-btn' + (favs.has(key) ? ' active' : '');
    btn.textContent = favs.has(key) ? '★' : '☆';
  }
}

function startFiltered(type){
  const targetSet = type==='fav' ? favs : weaks;
  if(targetSet.size===0) return;
  const filtered = DB.filter(h => targetSet.has(tileKey(h)));
  if(filtered.length===0) return;
  // 通常startGameと同様だが、問題セットをフィルタ済みに
  G.mode='free'; G.probs=shuffle(filtered); G.idx=0;
  G.score=0; G.cor=0; G.tot=0;
  G.timerSec=120; clearInterval(G.timerID);
  $('ss').style.display='none';
  $('rs').style.display='none';
  $('gs').style.display='block';
  $('sb').style.display='flex';
  const mt=$('mt');
  mt.textContent=type==='fav'?'お気に入り':'苦手問題'; mt.className='mtag free';
  $('dt').textContent='∞';
  G.filterType=type;
  loadQ();
}

// ═══════════════════════════════════════
// 手牌分解解説
// ═══════════════════════════════════════
function decomposeHand(tiles14){
  // 14枚を雀頭+面子4に分解、全パターン返却
  const c = new Array(10).fill(0);
  for(const t of tiles14) c[t]++;
  const results = [];
  const tried = new Set();
  for(const t of tiles14){
    if(tried.has(t)) continue;
    tried.add(t);
    if(c[t]>=2){
      c[t]-=2;
      const mentsuList = [];
      if(decomposeMentsu(c, 4, mentsuList)){
        results.push({ head:[t,t], mentsu: mentsuList.map(m=>[...m]) });
      }
      // 他の分解パターンも探す
      const allPatterns = [];
      findAllDecompositions(c, 4, [], allPatterns);
      for(const pattern of allPatterns){
        results.push({ head:[t,t], mentsu: pattern });
      }
      c[t]+=2;
    }
  }
  // 重複排除
  const unique = [];
  const seen = new Set();
  for(const r of results){
    const key = JSON.stringify({h:r.head, m:r.mentsu.map(m=>[...m].sort((a,b)=>a-b)).sort((a,b)=>a[0]-b[0]||a[1]-b[1])});
    if(!seen.has(key)){
      seen.add(key);
      unique.push(r);
    }
  }
  return unique;
}

function decomposeMentsu(c, rem, out){
  if(rem===0){
    for(let i=1;i<=9;i++) if(c[i]!==0) return false;
    return true;
  }
  let n=-1;
  for(let i=1;i<=9;i++){if(c[i]>0){n=i;break;}}
  if(n<0) return false;
  // 刻子
  if(c[n]>=3){
    c[n]-=3;
    out.push([n,n,n]);
    if(decomposeMentsu(c,rem-1,out)){c[n]+=3;return true;}
    out.pop();
    c[n]+=3;
  }
  // 順子
  if(n<=7&&c[n]>=1&&c[n+1]>=1&&c[n+2]>=1){
    c[n]--;c[n+1]--;c[n+2]--;
    out.push([n,n+1,n+2]);
    if(decomposeMentsu(c,rem-1,out)){c[n]++;c[n+1]++;c[n+2]++;return true;}
    out.pop();
    c[n]++;c[n+1]++;c[n+2]++;
  }
  return false;
}

function findAllDecompositions(c, rem, current, results){
  if(rem===0){
    for(let i=1;i<=9;i++) if(c[i]!==0) return;
    results.push(current.map(m=>[...m]));
    return;
  }
  let n=-1;
  for(let i=1;i<=9;i++){if(c[i]>0){n=i;break;}}
  if(n<0) return;
  // 刻子
  if(c[n]>=3){
    c[n]-=3;
    current.push([n,n,n]);
    findAllDecompositions(c,rem-1,current,results);
    current.pop();
    c[n]+=3;
  }
  // 順子
  if(n<=7&&c[n]>=1&&c[n+1]>=1&&c[n+2]>=1){
    c[n]--;c[n+1]--;c[n+2]--;
    current.push([n,n+1,n+2]);
    findAllDecompositions(c,rem-1,current,results);
    current.pop();
    c[n]++;c[n+1]++;c[n+2]++;
  }
}

function renderDecomposition(waitNum, decomps, suit){
  const div = document.createElement('div');
  div.className = 'decomp-wait';
  const sn = SUITS.find(s=>s.key===suit).label;
  const label = document.createElement('div');
  label.className = 'decomp-label';
  label.textContent = '待ち ' + waitNum + '（' + sn + '）';
  div.appendChild(label);

  // 最大3パターンまで表示
  const showCount = Math.min(decomps.length, 3);
  for(let i=0;i<showCount;i++){
    const d = decomps[i];
    const row = document.createElement('div');
    row.className = 'decomp-row';

    // 雀頭
    const headGroup = createGroup(d.head, suit, '雀頭');
    row.appendChild(headGroup);

    // 面子
    d.mentsu.forEach((m,mi) => {
      const plus = document.createElement('span');
      plus.className = 'decomp-plus';
      plus.textContent = '+';
      row.appendChild(plus);
      const mType = (m[0]===m[1]&&m[1]===m[2]) ? '刻子' : '順子';
      const mGroup = createGroup(m, suit, mType);
      row.appendChild(mGroup);
    });

    div.appendChild(row);
  }
  if(decomps.length > showCount){
    const more = document.createElement('div');
    more.style.cssText='font-size:10px;color:#6a5030;margin-top:2px';
    more.textContent = '他 ' + (decomps.length - showCount) + ' パターン';
    div.appendChild(more);
  }
  return div;
}

function createGroup(tiles, suit, label){
  const g = document.createElement('div');
  g.className = 'decomp-group';
  const lbl = document.createElement('span');
  lbl.className = 'decomp-group-label';
  lbl.textContent = label;
  g.appendChild(lbl);
  tiles.forEach(n => {
    const img = document.createElement('img');
    img.src = imgSrc(suit, n);
    img.className = 'decomp-tile';
    img.alt = n;
    g.appendChild(img);
  });
  return g;
}

function toggleDecomp(){
  const area = $('decompArea');
  const btn = $('decompToggle');
  if(area.classList.contains('show')){
    area.classList.remove('show');
    btn.textContent = '▼ 手牌の分解を見る';
  } else {
    area.classList.add('show');
    btn.textContent = '▲ 手牌の分解を閉じる';
  }
}

function showDecomposition(){
  const area = $('decompArea');
  const btn = $('decompToggle');
  area.innerHTML = '';
  btn.style.display = 'block';

  const tiles = [...G.probs[G.idx]].sort((a,b)=>a-b);
  const waits = G.waits;

  waits.forEach(w => {
    const tiles14 = [...tiles, w].sort((a,b)=>a-b);
    const decomps = decomposeHand(tiles14);
    if(decomps.length > 0){
      const el = renderDecomposition(w, decomps, G.suit);
      area.appendChild(el);
    }
  });
}
"""

# スクリプト末尾の $('ss').style.display='flex'; の前に追加JS挿入
# toTop内の同名文にはマッチしないよう、末尾のもの（\n$('ss')で始まる行）を狙う
html = html.replace(
    "\n$('ss').style.display='flex';\n</script>",
    "\n" + additional_js + "\nupdateFilterUI();\n$('ss').style.display='flex';\n</script>"
)

# ── 5. loadQ関数にお気に入りボタンを追加 ──
# hw.innerHTML='' の後にお気に入りボタンを追加
old_hw = "const hw = $('hw'); hw.innerHTML='';"
new_hw = """const hw = $('hw'); hw.innerHTML='';
  // お気に入りボタン
  const favBtn = document.createElement('button');
  favBtn.className = 'fav-btn';
  favBtn.onclick = toggleFavorite;
  hw.appendChild(favBtn);
  updateFavBtn();"""
html = html.replace(old_hw, new_hw)

# ── 6. doConfirm関数に苦手問題ロジックと解説表示を追加 ──
# 答え合わせ時に苦手問題の自動登録/削除を追加

# doConfirm内、$('bnx').style.display='block'; の後に苦手問題ロジック追加
old_bnx = "else $('bnx').style.display='block';"
new_bnx = """else $('bnx').style.display='block';

  // 苦手問題ロジック
  const probKey = tileKey(G.probs[G.idx]);
  if(perfect){
    // 正解: お気に入りでなければ苦手から削除
    if(weaks.has(probKey) && !favs.has(probKey)){
      weaks.delete(probKey);
      saveSet('chinitsu_weak', weaks);
      const wn=document.createElement('div');wn.className='weak-notice';wn.textContent='✓ 苦手問題リストから削除しました';
      fb.appendChild(wn);
    }
  } else {
    // 不正解: 苦手に自動登録
    if(!weaks.has(probKey)){
      weaks.add(probKey);
      saveSet('chinitsu_weak', weaks);
      const wn=document.createElement('div');wn.className='weak-notice';wn.textContent='▼ 苦手問題リストに追加しました';
      fb.appendChild(wn);
    }
  }
  updateFilterUI();

  // 手牌分解解説を表示準備
  showDecomposition();"""

html = html.replace(old_bnx, new_bnx)

# ── 7. doNext / loadQ で分解エリアをリセット ──
old_loadq_reset = "$('fb').className='fb'; $('fb').innerHTML='';"
new_loadq_reset = """$('fb').className='fb'; $('fb').innerHTML='';
  $('decompArea').innerHTML=''; $('decompArea').classList.remove('show');
  $('decompToggle').style.display='none';"""
html = html.replace(old_loadq_reset, new_loadq_reset)

# ── 8. toTop関数でフィルターUIを更新 ──
old_totop = "function toTop(){"
new_totop = "function toTop(){ updateFilterUI();"
html = html.replace(old_totop, new_totop)

# ── 書き出し ──
dst.write_text(html, encoding='utf-8')
print(f"✅ パッチ適用完了: {dst}")
print(f"  ファイルサイズ: {dst.stat().st_size:,} bytes")
