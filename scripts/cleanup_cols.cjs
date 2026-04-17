const fs = require('fs');
const path = require('path');

const baseDir = path.join('c:', 'Projetos', 'Football Collection', 'paises');

function walk(dir) {
    let results = [];
    if (!fs.existsSync(dir)) return results;
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else {
            if (file.endsWith('.htm') || file.endsWith('.html')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk(baseDir);

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    if (content.includes('cols-3')) {
        console.log(`Cleaning up cols-3 in: ${file}`);
        content = content.replace(/class="gallery cols-3"/g, 'class="gallery"');
        fs.writeFileSync(file, content, 'utf8');
    }
});

console.log('Cleanup complete!');
