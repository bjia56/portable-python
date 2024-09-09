export interface IInstallerProps {
    pythonDistributionName: string;
}

export interface IInstaller extends IInstallerProps {
    relativeExecutablePath: string;
    relativePipPath: string;
    validateOptions(): void;
    postInstall(): Promise<void>;
}

export interface IPortablePython extends IInstallerProps {
    version: string;
    major: string;
    minor: string;
    patch: string;
    releaseTag: string;
    implementation: string;
    distribution: string;
    installDir: string;
    extractPath: string;
    executablePath: string;
    pipPath: string;

    isInstalled(): boolean;
    install(zipFile: string | null): Promise<void>;
    uninstall(): Promise<void>;
}

export interface IPortablePythonOptions {
    implementation?: string;
    distribution?: string;

    /**
     * Override the version of Python to install. For development use only.
     */
    _versionOverride?: string;

    /**
     * Override the release tag of Python to install. For development use only.
     */
    _tagOverride?: string;
}