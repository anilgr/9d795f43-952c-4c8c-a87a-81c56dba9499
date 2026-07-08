const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const withAnimatedSplash = (config) => {
    return withDangerousMod(config, [
        'android',
        async (config) => {
            const resDir = path.join(config.modRequest.platformProjectRoot, 'app', 'src', 'main', 'res');
            const sourceDir = path.join(config.modRequest.projectRoot, 'assets', 'native-splash');

            // Copy drawables
            const drawableDest = path.join(resDir, 'drawable');
            fs.mkdirSync(drawableDest, { recursive: true });
            ['card.xml', 'animated_splash.xml'].forEach(file => {
                const srcPath = path.join(sourceDir, 'drawable', file);
                if (fs.existsSync(srcPath)) {
                    fs.copyFileSync(srcPath, path.join(drawableDest, file));
                }
            });

            // Copy animators
            const animatorDest = path.join(resDir, 'animator');
            fs.mkdirSync(animatorDest, { recursive: true });
            const sourceAnimatorDir = path.join(sourceDir, 'animator');
            if (fs.existsSync(sourceAnimatorDir)) {
                const animators = fs.readdirSync(sourceAnimatorDir);
                animators.forEach(file => {
                    if (file.endsWith('.xml')) {
                        fs.copyFileSync(path.join(sourceAnimatorDir, file), path.join(animatorDest, file));
                    }
                });
            }

            // Bulletproof workaround: Wait until Expo finishes the entire prebuild
            // and is shutting down before we forcefully rewrite styles.xml text.
            process.on('exit', () => {
                const stylesPath = path.join(resDir, 'values', 'styles.xml');
                if (fs.existsSync(stylesPath)) {
                    let content = fs.readFileSync(stylesPath, 'utf8');
                    
                    // Replace Expo's generated splash screen with our animated_splash
                    content = content.replace(/@drawable\/splashscreen_logo/g, '@drawable/animated_splash');
                    // Ensure the background is exactly #222222 to match Ionic
                    content = content.replace(/@color\/splashscreen_background/g, '#222222');
                    
                    fs.writeFileSync(stylesPath, content, 'utf8');
                    console.log('\n[AnimatedSplash Plugin] Successfully applied animated_splash to styles.xml strictly after Expo finished!\n');
                }
            });

            return config;
        },
    ]);
};

module.exports = function(config) {
    return withAnimatedSplash(config);
};
