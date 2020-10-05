const core = require('../.modules/@actions/core');
const exec = require('../.modules/@actions/exec');

(async () => {
    try {
        const dockerfile = core.getInput('dockerfile');
        const architecture = core.getInput('architecture');

        const gitRepo = process.env.GITHUB_REPOSITORY.split('/');
        const gitRef = process.env.GITHUB_REF.split('/').pop();
        const gitTag = gitRef.match(/^v((?:\.?\d+)+(?:-.+)?)$/);

        const image = `${gitRepo[0]}/${gitRepo[1]}`;
        const tag = `${architecture}-${gitTag ? gitTag[1] : gitRef}`;

        await exec.exec('docker run --rm --privileged multiarch/qemu-user-static:register --reset');

        await exec.exec('docker build .', [
            `--file=${dockerfile}`,
            `--build-arg=BUILD_DATE=${new Date().toISOString()}`,
            `--build-arg=VCS_REF=${process.env.GITHUB_SHA.slice(0, 7)}`,
            `--tag=${image}:${tag}`,
            '--no-cache'
        ]);

        await exec.exec(`docker push ${image}:${tag}`);

        if (gitTag) {
            const latestTag = tag.replace(gitTag[1], 'latest');

            await exec.exec(`docker tag ${image}:${tag} ${image}:${latestTag}`);
            await exec.exec(`docker push ${image}:${latestTag}`);
        }
    } catch (error) {
        core.setFailed(error);
    }
})();
