const core = require('../.modules/@actions/core');
const exec = require('../.modules/@actions/exec');

async function createAndPushManifest(architectures, image, metaTag) {
    const manifest = [`${image}:${metaTag}`];

    for (let architecture of architectures) {
        manifest.push(`${image}:${architecture}-${metaTag}`);

        await exec.exec(`docker pull ${image}:${architecture}-${metaTag}`);
    }

    await exec.exec('docker manifest create', manifest);

    for (let architecture of architectures) {
        const matches = architecture.match(/^([a-z]+(?:32|64))(v[0-9])?$/);

        const arch = matches[1].replace(32, '');
        const variant = matches[2];

        if (arch && variant) {
            await exec.exec('docker manifest annotate', [
                manifest[0],
                `${image}:${architecture}-${metaTag}`,
                `--os=linux`,
                `--arch=${arch}`,
                `--variant=${arch.replace(64, '')}${variant}`
            ]);
        }
    }

    await exec.exec(`docker manifest push --purge ${manifest[0]}`);
}

(async () => {
    try {
        const architectures = JSON.parse(core.getInput('multiarch'));

        const gitRepo = process.env.GITHUB_REPOSITORY.split('/');
        const gitRef = process.env.GITHUB_REF.split('/').pop();
        const gitTag = gitRef.match(/^v((?:\.?\d+)+(?:-.+)?)$/);

        const image = `${gitRepo[0]}/${gitRepo[1].replace('docker-', '')}`;
        const tag = gitTag ? gitTag[1] : gitRef;

        await createAndPushManifest(architectures, image, tag);

        if (gitTag) {
            await createAndPushManifest(architectures, image, 'latest');
        }
    } catch (error) {
        core.setFailed(error);
    }
})();
