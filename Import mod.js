function importMod() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.zip,.lua';
    input.onchange = function(e) {
        const file = e.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = function(e) {
            const data = e.target.result;
            const request = indexedDB.open('ModHubFinal', 1);
            request.onsuccess = function(event) {
                const db = event.target.result;
                const tx = db.transaction('mods', 'readwrite');
                const store = tx.objectStore('mods');
                
                store.put({
                    title: file.name.replace(/\.[^.]+$/, ''),
                    desc: 'Импортированный мод',
                    zipData: data,
                    zipName: file.name,
                    isMod: true,
                    downloads: 0,
                    likes: 0,
                    dislikes: 0,
                    author: currentUser ? currentUser.username : 'Аноним',
                    createdAt: Date.now()
                });
                
                tx.oncomplete = function() {
                    alert('✅ Мод "' + file.name + '" импортирован!');
                    loadMods();
                };
            };
        };
        reader.readAsDataURL(file);
    };
    input.click();
}
